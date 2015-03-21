//
//  Broadcaster.swift
//  PersonLog
//
//  Created by Yasyf Mohamedali on 2015-03-17.
//  Copyright (c) 2015 Yasyf Mohamedali. All rights reserved.
//

import Foundation
import MultipeerConnectivity

class Broadcaster: NSObject, MCNearbyServiceAdvertiserDelegate {
    let peerID: MCPeerID
    let advertiser: MCNearbyServiceAdvertiser
    var isBroadcasting: Bool = false
    
    init(peerID: MCPeerID, serviceType: String) {
        self.peerID = peerID
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType as NSString)
        super.init()
        advertiser.delegate = self
    }
    
    func broadcast() {
        advertiser.startAdvertisingPeer()
        isBroadcasting = true
    }
    
    func kill() {
        isBroadcasting = false
        advertiser.startAdvertisingPeer()
    }
    
    // MARK: - MCNearbyServiceAdvertiserDelegate
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser!, didReceiveInvitationFromPeer peerID: MCPeerID!, withContext context: NSData!, invitationHandler: ((Bool, MCSession!) -> Void)!) {
        NSLog("Ignoring invitation from \(peerID)")
        invitationHandler(false, nil)
    }
    
}