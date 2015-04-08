//
//  Broadcaster.swift
//  PersonLog
//
//  Created by Yasyf Mohamedali on 2015-03-17.
//  Copyright (c) 2015 Yasyf Mohamedali. All rights reserved.
//

import Foundation
import MultipeerConnectivity
import CoreLocation
import CoreBluetooth

class Broadcaster: NSObject, MCNearbyServiceAdvertiserDelegate, CBPeripheralManagerDelegate {
    let serviceType: String
    let beaconID: NSUUID
    let characteristicID: CBUUID
    let peer: Peer
    var advertiser: MCNearbyServiceAdvertiser?
    let peripheralManager: CBPeripheralManager?
    var isBroadcasting: Bool = false
    
    init(peer: Peer, serviceType: String, beaconID: NSUUID, characteristicID: CBUUID) {
        self.peer = peer
        self.serviceType = serviceType
        self.beaconID = beaconID
        self.characteristicID = characteristicID
        super.init()
        self.peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: [CBPeripheralManagerOptionRestoreIdentifierKey: "broadcasterPeripheralManager"])
    }
    
    func startAdvertising(deviceID: String) {
        if let manager = self.peripheralManager {
            let serviceUUID = CBUUID(NSUUID: beaconID)
            let characteristic = CBMutableCharacteristic(type: characteristicID, properties: CBCharacteristicProperties.Read, value: deviceID.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false), permissions: CBAttributePermissions.Readable)
            let service = CBMutableService(type: serviceUUID, primary: true)
            service.characteristics = [characteristic]
            manager.addService(service)
            println("addService \(service)")
            manager.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [serviceUUID]])
        }
    }
    
    func broadcast() {
        peer.onPeerID({(peerID: MCPeerID) in
            if self.advertiser == nil {
                self.advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: self.serviceType)
                self.advertiser!.delegate = self
            }
            self.advertiser!.startAdvertisingPeer()
            self.startAdvertising(peerID.displayName)
            self.isBroadcasting = true
        })
    }
    
    func kill() {
        isBroadcasting = false
        advertiser?.stopAdvertisingPeer()
        peripheralManager!.stopAdvertising()
    }
    
    // MARK: - CBPeripheralManagerDelegate
    
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager!) {
        if peripheral.state == CBPeripheralManagerState.PoweredOn && isBroadcasting {
            self.peer.onPeerID({(peerID: MCPeerID) in
                self.startAdvertising(peerID.displayName)
            })
        }
    }
    
    func peripheralManagerDidStartAdvertising(peripheral: CBPeripheralManager!, error: NSError!) {
        println("peripheralManagerDidStartAdvertising (Error: \(error))")
    }
    
    func peripheralManager(peripheral: CBPeripheralManager!, willRestoreState dict: [NSObject : AnyObject]!) {
        println("peripheralManager:willRestoreState")
    }
    
    // MARK: - MCNearbyServiceAdvertiserDelegate
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser!, didReceiveInvitationFromPeer peerID: MCPeerID!, withContext context: NSData!, invitationHandler: ((Bool, MCSession!) -> Void)!) {
        NSLog("Ignoring invitation from \(peerID)")
        invitationHandler(false, nil)
    }
    
}