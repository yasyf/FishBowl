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
    let serviceType: String
    let peer: Peer
    var advertiser: MCNearbyServiceAdvertiser?
    var isBroadcasting: Bool = false
    
    init(peer: Peer, serviceType: String) {
        self.peer = peer
        self.serviceType = serviceType
        super.init()
    }
    
    func broadcast() {
        peer.onPeerID({(peerID: MCPeerID) in
            if self.advertiser == nil {
                self.advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: self.serviceType as NSString)
                self.advertiser!.delegate = self
            }
            self.advertiser!.startAdvertisingPeer()
            self.isBroadcasting = true
        })
    }
    
    func kill() {
        isBroadcasting = false
        advertiser?.startAdvertisingPeer()
    }
    
    // MARK: - MCNearbyServiceAdvertiserDelegate
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser!, didReceiveInvitationFromPeer peerID: MCPeerID!, withContext context: NSData!, invitationHandler: ((Bool, MCSession!) -> Void)!) {
        NSLog("Ignoring invitation from \(peerID)")
        invitationHandler(false, nil)
    }
    
}