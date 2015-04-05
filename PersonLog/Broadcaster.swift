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
    let peer: Peer
    var advertiser: MCNearbyServiceAdvertiser?
    var beaconRegion: CLBeaconRegion?
    let peripheralManager = CBPeripheralManager()
    var isBroadcasting: Bool = false
    
    init(peer: Peer, serviceType: String, beaconID: NSUUID) {
        self.peer = peer
        self.serviceType = serviceType
        self.beaconID = beaconID
        super.init()
        self.peripheralManager.delegate = self
    }
    
    func broadcast() {
        peer.onPeerID({(peerID: MCPeerID) in
            if self.advertiser == nil {
                self.advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: self.serviceType)
                self.advertiser!.delegate = self
            }
            if self.beaconRegion == nil {
                self.beaconRegion = CLBeaconRegion(proximityUUID: self.beaconID, identifier: peerID.displayName)
            }
            self.advertiser!.startAdvertisingPeer()
            self.peripheralManager.startAdvertising(self.beaconRegion!.peripheralDataWithMeasuredPower(nil))
            self.isBroadcasting = true
        })
    }
    
    func kill() {
        isBroadcasting = false
        advertiser?.startAdvertisingPeer()
        peripheralManager.stopAdvertising()
    }
    
    // MARK: - CBPeripheralManagerDelegate
    
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager!) {
        if peripheral.state == CBPeripheralManagerState.PoweredOn {
            println("peripheralManagerDidUpdateState PoweredOn")
        }
    }
    
    // MARK: - MCNearbyServiceAdvertiserDelegate
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser!, didReceiveInvitationFromPeer peerID: MCPeerID!, withContext context: NSData!, invitationHandler: ((Bool, MCSession!) -> Void)!) {
        NSLog("Ignoring invitation from \(peerID)")
        invitationHandler(false, nil)
    }
    
}