//
//  Discoverer.swift
//  PersonLog
//
//  Created by Yasyf Mohamedali on 2015-03-17.
//  Copyright (c) 2015 Yasyf Mohamedali. All rights reserved.
//

import Foundation
import MultipeerConnectivity
import CoreLocation
import CoreBluetooth
import Localytics

enum PowerMode {
    case Unknown
    case Low
    case Medium
    case High
}

class PeerTask: NSObject {
    let callback: () -> Void
    var completed = false
    let peer: Peer
    
    init(peer: Peer, callback: () -> Void) {
        self.callback = callback
        self.peer = peer
        super.init()
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(60 * Double(NSEC_PER_SEC))), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), self.run)
    }
    
    func run() {
        if !completed {
            completed = true
            callback()
        }
    }
}

class Discoverer: NSObject, MCNearbyServiceBrowserDelegate, CLLocationManagerDelegate, CBCentralManagerDelegate, CBPeripheralDelegate {
    let serviceType: String
    let beaconID: NSUUID
    let characteristicID: CBUUID
    var browser: MCNearbyServiceBrowser?
    var centralManager: CBCentralManager?
    let peer: Peer
    var peers: [Peer] = []
    var peripherals: [CBPeripheral] = []
    var peerCallbacks: [(Peer) -> Void] = []
    var newLocationCallbacks: [() -> Void] = []
    let newLocationCallbackLock = 0
    var otherUpdateCallbacks: [() -> Void] = []
    var isDiscovering: Bool = false
    var isLocating: Bool = false
    var powerMode: PowerMode = .Unknown
    var locManager = CLLocationManager()
    var lastState = CBCentralManagerState.Unknown
    var processLocationTimer: NSTimer?
    var medPowerTimer: NSTimer?
    var locManagerAuthorizationStatus = CLAuthorizationStatus.NotDetermined
    
    init(peer: Peer, serviceType: String, beaconID: NSUUID, characteristicID: CBUUID) {
        self.peer = peer
        self.serviceType = serviceType
        self.beaconID = beaconID
        self.characteristicID = characteristicID
        super.init()
        self.locManager.delegate = self
        self.locManager.pausesLocationUpdatesAutomatically = true
        self.locManager.activityType = CLActivityType.Fitness
        self.locManager.desiredAccuracy = kCLLocationAccuracyBest
        self.centralManager = CBCentralManager(delegate: self, queue: dispatch_queue_create("com.fishbowl.CentralManagerQueue", DISPATCH_QUEUE_SERIAL), options: [CBCentralManagerOptionRestoreIdentifierKey: "discovererCentralManager"])
    }
    
    func onPeer(callback: (Peer) -> Void) {
        peerCallbacks.append(callback)
        peers.map(callback)
    }

    func onNewLocation(callback: () -> Void) {
        newLocationCallbacks.append(callback)
    }
    
    func onOtherUpdate(callback: () -> Void) {
        otherUpdateCallbacks.append(callback)
    }
    
    func triggerUpdate() {
        for callback in otherUpdateCallbacks {
            callback()
        }
    }
    
    func startDiscoveringWithManager() {
        if let manager = centralManager {
            let serviceUUIDs = [CBUUID(NSUUID: beaconID)]
            CLS_LOG_SWIFT("scanForPeripheralsWithServices \(serviceUUIDs)")
            let options = [CBCentralManagerScanOptionSolicitedServiceUUIDsKey:serviceUUIDs]
            manager.scanForPeripheralsWithServices(serviceUUIDs, options: options)
        }
    }
    
    func startDiscoveringWithBrowser() {
        self.browser!.startBrowsingForPeers()
    }
    
    func startDiscovering() {
        self.isLocating = true
        goHighPower()
        startDiscoveringWithBrowser()
        self.startDiscoveringWithManager()
    }
    
    func discover() {
        peer.onPeerID({(peerID: MCPeerID) in
            if self.browser == nil {
                self.browser = MCNearbyServiceBrowser(peer: peerID, serviceType: self.serviceType)
                self.browser!.delegate = self
            }
            self.isDiscovering = true
            if self.locManagerAuthorizationStatus == .AuthorizedAlways {
                self.startDiscovering()
            } else {
                self.locManager.requestAlwaysAuthorization()
            }
        })
    }
    
    func stopLocationServices() {
        CLS_LOG_SWIFT("Stopping location services!")
        self.killTimer(processLocationTimer)
        self.killTimer(medPowerTimer)
        self.locManager.stopUpdatingLocation()
        self.locManager.stopMonitoringSignificantLocationChanges()
    }
    
    func goLowPower() {
        if powerMode == .Low {
            return
        }
        self.powerMode = .Low
        stopLocationServices()
        CLS_LOG_SWIFT("Going low power for location services!")
        self.locManager.startMonitoringSignificantLocationChanges()
    }
    
    func goMediumPower() {
        if powerMode == .Medium {
            return
        }
        self.powerMode = .Medium
        stopLocationServices()
        CLS_LOG_SWIFT("Going medium power for location services!")
        self.locManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        self.locManager.startUpdatingLocation()
    }
    
    func goHighPower() {
        if powerMode == .High {
            return
        }
        self.powerMode = .High
        stopLocationServices()
        CLS_LOG_SWIFT("Going high power for location services!")
        self.locManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locManager.startUpdatingLocation()
    }
    
    func killTimer(timerOptional: NSTimer?) {
        if let timer = timerOptional {
            timer.invalidate()
        }
    }
    
    func kill() {
        isDiscovering = false
        isLocating = false
        browser?.stopBrowsingForPeers()
        centralManager?.stopScan()
        stopLocationServices()
    }
    
    func didFindPeer(peer: Peer) {
        peer.onPeerID({(peerID: MCPeerID) in
            CLS_LOG_SWIFT("Found peer \(peerID.displayName)")
        })
        peer.onData({(data: Dictionary<String, AnyObject>) in
            CLS_LOG_SWIFT("%@", [data])
        })
        peers.append(peer)
        let peerTask = PeerTask(peer: peer, callback: {
            for callback in self.peerCallbacks {
                callback(peer)
            }
        })
        onNewLocation({
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), peerTask.run)
        })
        goHighPower()
    }
    
    func connectPeripheral(central: CBCentralManager, peripheral: CBPeripheral) {
        CLS_LOG_SWIFT("didDiscoverPeripheral \(peripheral)")
        peripherals.append(peripheral)
        peripheral.delegate = self
        central.connectPeripheral(peripheral, options: nil)
    }
    
    // MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(central: CBCentralManager!) {
        lastState = central.state
        if lastState == .PoweredOn {
            Localytics.tagEvent("BluetoothStatus", attributes: ["status": "enabled"])
            if isDiscovering {
                CLS_LOG_SWIFT("centralManagerDidUpdateState PoweredOn")
                startDiscoveringWithManager()
            }
        } else if lastState == .PoweredOff {
            Localytics.tagEvent("BluetoothStatus", attributes: ["status": "disabled"])
        }
    }
    
    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        connectPeripheral(central, peripheral: peripheral)
    }
    
    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        let serviceUUID = CBUUID(NSUUID: beaconID)
        peripheral.discoverServices([serviceUUID])
    }
    
    func centralManager(central: CBCentralManager!, didFailToConnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        CLS_LOG_SWIFT("didFailToConnectPeripheral \(error)")
    }
    
    func centralManager(central: CBCentralManager!, willRestoreState dict: [NSObject : AnyObject]!) {
        CLS_LOG_SWIFT("centralManager:willRestoreState")
        if let restoredPeripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] {
            for peripheral in restoredPeripherals {
                connectPeripheral(central, peripheral: peripheral)
            }
        }
    }
    
    // MARK: - CBPeripheralDelegate
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverServices error: NSError!) {
        if let err = error {
            CLS_LOG_SWIFT("peripheral:didDiscoverServices:error: %@", [err])
        }
        else {
            if peripheral.services.count > 0 {
                if let service = peripheral.services[0] as? CBService {
                    peripheral.discoverCharacteristics([characteristicID], forService: service)
                }
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverCharacteristicsForService service: CBService!, error: NSError!) {
        if let err = error {
            CLS_LOG_SWIFT("peripheral:didDiscoverCharacteristicsForService:error: %@", [err])
        } else {
            if service.characteristics.count > 0 {
                if let characteristic = service.characteristics[0] as? CBCharacteristic {
                    peripheral.readValueForCharacteristic(characteristic)
                }
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didUpdateValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        let UUIDString = NSString(data: characteristic.value, encoding: NSUTF8StringEncoding)
        let peerID = MCPeerID(displayName: UUIDString! as String)
        let peer = Peer(peerID: peerID)
        didFindPeer(peer)
        for (i, periph) in enumerate(peripherals) {
            if periph == peripheral {
                peripherals.removeAtIndex(i)
                break
            }
        }
    }
    

    // MARK: - CLLocationManagerDelegate
    
    func goLowWithSchedule() {
        goLowPower()
        medPowerTimer = NSTimer.scheduledTimerWithTimeInterval(600, target: self, selector: Selector("goMediumPower"), userInfo: nil, repeats: false)
    }
    
    func processLocation(location: CLLocation) {
        self.peer.setLocation(location)
        Localytics.setLocation(location.coordinate)
        
        objc_sync_enter(newLocationCallbackLock)
        let savedCallbacks = newLocationCallbacks
        newLocationCallbacks.removeAll(keepCapacity: false)
        objc_sync_exit(newLocationCallbackLock)
        
        for callback in savedCallbacks {
            callback()
        }
        goLowWithSchedule()
    }
    
    func processLocationFromTimer(timer: NSTimer) {
        let location = timer.userInfo as! CLLocation
        processLocation(location)
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        if let location = locations.last as? CLLocation {
            if !(location.horizontalAccuracy > peer._location?.horizontalAccuracy) {
                processLocation(location)
            }
            else if location.horizontalAccuracy > 0 && location.horizontalAccuracy <= 50 {
                if location.horizontalAccuracy <= 30 {
                    processLocationTimer?.invalidate()
                    processLocation(location)
                } else {
                    if !(processLocationTimer?.valid == true) {
                        processLocationTimer = NSTimer.scheduledTimerWithTimeInterval(30, target: self, selector: Selector("processLocationFromTimer:"), userInfo: location, repeats: false)
                    }
                }
            } else {
                if powerMode == .Medium {
                    goLowWithSchedule()
                }
            }
        }
    }
    
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        CLS_LOG_SWIFT("locationManager:didFailWithError: %@", [error])
    }
    
    func locationManager(manager: CLLocationManager!, didEnterRegion region: CLRegion!) {
        CLS_LOG_SWIFT("didEnterRegion \(region)")
    }
    
    func locationManager(manager: CLLocationManager!, didExitRegion region: CLRegion!) {
        CLS_LOG_SWIFT("didExitRegion \(region)")
    }
    
    func locationManager(manager: CLLocationManager!, didRangeBeacons beacons: [AnyObject]!, inRegion region: CLBeaconRegion!) {
        CLS_LOG_SWIFT("didRangeBeacons \(beacons)")
    }
    
    func locationManager(manager: CLLocationManager!, didStartMonitoringForRegion region: CLRegion!) {
        CLS_LOG_SWIFT("didStartMonitoringForRegion \(region)")
    }
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        locManagerAuthorizationStatus = status
        if locManagerAuthorizationStatus == .AuthorizedAlways {
            if isDiscovering && !isLocating {
                startDiscovering()
            }
        } else {
            CLS_LOG_SWIFT("CLLocationManager authorization failed")
            kill()
        }
    }
    
    // MARK: - MCNearbyServiceBrowserDelegate
    
    func browser(browser: MCNearbyServiceBrowser!, foundPeer peerID: MCPeerID!, withDiscoveryInfo info: [NSObject : AnyObject]!) {
        let peer = Peer(peerID: peerID)
        didFindPeer(peer)
    }
    
    func browser(browser: MCNearbyServiceBrowser!, lostPeer peerID: MCPeerID!) {
        CLS_LOG_SWIFT("Lost peer \(peerID)")
        for (i, peer) in enumerate(peers) {
            if peer.peerID == peerID {
                peers.removeAtIndex(i)
                break
            }
        }
    }
}