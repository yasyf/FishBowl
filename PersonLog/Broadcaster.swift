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
    var sessions: [Session] = []
    
    init(peerID: MCPeerID, serviceType: String) {
        self.peerID = peerID
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
        super.init()
        advertiser.delegate = self
    }
    
    func broadcast() {
        advertiser.startAdvertisingPeer()
    }
    
    func kill() {
        advertiser.startAdvertisingPeer()
    }
    
    // MARK: - MCNearbyServiceAdvertiserDelegate
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser!, didReceiveInvitationFromPeer peerID: MCPeerID!, withContext context: NSData!, invitationHandler: ((Bool, MCSession!) -> Void)!) {
        if peerID == self.peerID {
            NSLog("Ignoring invitation from \(peerID)")
            invitationHandler(false, nil)
        } else {
            let session = Session(peerID: peerID)
            sessions.append(session)
            invitationHandler(true, session.session)
        }
    }
    
}