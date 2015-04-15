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
    var otherUpdateCallbacks: [() -> Void] = []
    var isDiscovering: Bool = false
    var locManager = CLLocationManager()
    
    init(peer: Peer, serviceType: String, beaconID: NSUUID, characteristicID: CBUUID) {
        self.peer = peer
        self.serviceType = serviceType
        self.beaconID = beaconID
        self.characteristicID = characteristicID
        super.init()
        self.locManager.delegate = self
        self.locManager.pausesLocationUpdatesAutomatically = true
        self.locManager.activityType = CLActivityType.Fitness
        self.locManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        self.centralManager = CBCentralManager(delegate: self, queue: dispatch_queue_create("com.fishbowl.CentralManagerQueue", DISPATCH_QUEUE_SERIAL), options: [CBCentralManagerOptionRestoreIdentifierKey: "discovererCentralManager"])
    }
    
    func onPeer(callback: (Peer) -> Void) {
        peerCallbacks.append(callback)
        peers.map(callback)
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
            NSLog("scanForPeripheralsWithServices \(serviceUUIDs)")
            let options = [CBCentralManagerScanOptionSolicitedServiceUUIDsKey:serviceUUIDs]
            manager.scanForPeripheralsWithServices(serviceUUIDs, options: options)
        }
    }
    
    func startDiscoveringWithBrowser() {
        self.browser!.startBrowsingForPeers()
    }
    
    func startDiscovering() {
        self.locManager.startUpdatingLocation()
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
            self.locManager.requestAlwaysAuthorization()
        })
    }
    
    func kill() {
        isDiscovering = false
        browser?.stopBrowsingForPeers()
        centralManager?.stopScan()
        self.locManager.stopUpdatingLocation()
    }
    
    func didFindPeer(peer: Peer) {
        peer.onPeerID({(peerID: MCPeerID) in
            NSLog("Found peer \(peerID.displayName)")
        })
        peer.onData({(data: Dictionary<String, AnyObject>) in
            NSLog("%@", data)
        })
        peers.append(peer)
        for callback in peerCallbacks {
            callback(peer)
        }
    }
    
    func connectPeripheral(central: CBCentralManager, peripheral: CBPeripheral) {
        NSLog("didDiscoverPeripheral \(peripheral)")
        peripherals.append(peripheral)
        peripheral.delegate = self
        central.connectPeripheral(peripheral, options: nil)
    }
    
    // MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(central: CBCentralManager!) {
        if central.state == CBCentralManagerState.PoweredOn && isDiscovering {
            NSLog("centralManagerDidUpdateState PoweredOn")
            startDiscoveringWithManager()
        }
    }
    
    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        connectPeripheral(central, peripheral: peripheral)
    }
    
    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        NSLog("didConnectPeripheral \(peripheral)")
        let serviceUUID = CBUUID(NSUUID: beaconID)
        peripheral.discoverServices([serviceUUID])
    }
    
    func centralManager(central: CBCentralManager!, didFailToConnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        NSLog("didFailToConnectPeripheral \(error)")
    }
    
    func centralManager(central: CBCentralManager!, willRestoreState dict: [NSObject : AnyObject]!) {
        NSLog("centralManager:willRestoreState")
        if let restoredPeripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] {
            for peripheral in restoredPeripherals {
                connectPeripheral(central, peripheral: peripheral)
            }
        }
    }
    
    // MARK: - CBPeripheralDelegate
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverServices error: NSError!) {
        if let err = error {
            NSLog("peripheral:didDiscoverServices:error: %@", err)
        }
        else {
            if peripheral.services.count > 0 {
                if let service = peripheral.services[0] as? CBService {
                    NSLog("didDiscoverService \(service)")
                    peripheral.discoverCharacteristics([characteristicID], forService: service)
                }
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverCharacteristicsForService service: CBService!, error: NSError!) {
        let characteristic = service.characteristics[0] as! CBCharacteristic
        peripheral.readValueForCharacteristic(characteristic)
        NSLog("didDiscoverCharacteristicsForService \(service.characteristics)")
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
    func locationManager(manager: CLLocationManager!, didUpdateToLocation newLocation: CLLocation!, fromLocation oldLocation: CLLocation!) {
        self.peer.location = newLocation
        Localytics.setLocation(newLocation.coordinate)
    }
    
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        NSLog("locationManager:didFailWithError: %@", error)
    }
    
    func locationManager(manager: CLLocationManager!, didEnterRegion region: CLRegion!) {
        NSLog("didEnterRegion \(region)")
    }
    
    func locationManager(manager: CLLocationManager!, didExitRegion region: CLRegion!) {
        NSLog("didExitRegion \(region)")
    }
    
    func locationManager(manager: CLLocationManager!, didRangeBeacons beacons: [AnyObject]!, inRegion region: CLBeaconRegion!) {
        NSLog("didRangeBeacons \(beacons)")
    }
    
    func locationManager(manager: CLLocationManager!, didStartMonitoringForRegion region: CLRegion!) {
        NSLog("didStartMonitoringForRegion \(region)")
    }
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.AuthorizedAlways {
            if isDiscovering {
                startDiscovering()
            }
        } else {
            NSLog("CLLocationManager authorization failed")
            kill()
        }
    }
    
    // MARK: - MCNearbyServiceBrowserDelegate
    
    func browser(browser: MCNearbyServiceBrowser!, foundPeer peerID: MCPeerID!, withDiscoveryInfo info: [NSObject : AnyObject]!) {
        let peer = Peer(peerID: peerID)
        didFindPeer(peer)
    }
    
    func browser(browser: MCNearbyServiceBrowser!, lostPeer peerID: MCPeerID!) {
        NSLog("Lost peer \(peerID)")
        for (i, peer) in enumerate(peers) {
            if peer.peerID == peerID {
                peers.removeAtIndex(i)
                break
            }
        }
    }
}