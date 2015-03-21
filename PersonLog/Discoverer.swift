//
//  Discoverer.swift
//  PersonLog
//
//  Created by Yasyf Mohamedali on 2015-03-17.
//  Copyright (c) 2015 Yasyf Mohamedali. All rights reserved.
//

import Foundation
import MultipeerConnectivity

class Discoverer: NSObject, MCNearbyServiceBrowserDelegate {
    let browser: MCNearbyServiceBrowser
    let peerID: MCPeerID
    var sessions: [Session] = []
    var isDiscovering: Bool = false
    
    init(peerID: MCPeerID, serviceType: String) {
        self.peerID = peerID
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        super.init()
        browser.delegate = self
    }
    
    func discover() {
        browser.startBrowsingForPeers()
        isDiscovering = true
    }
    
    func kill() {
        isDiscovering = false
        browser.stopBrowsingForPeers()
    }
    
    func browser(browser: MCNearbyServiceBrowser!, foundPeer peerID: MCPeerID!, withDiscoveryInfo info: [NSObject : AnyObject]!) {
        NSLog("Found peer \(peerID) with discovery info \(info)")
        let session = Session(peerID: peerID)
        sessions.append(session)
        browser.invitePeer(peerID, toSession: session.session, withContext: nil, timeout: 20)
    }
    
    func browser(browser: MCNearbyServiceBrowser!, lostPeer peerID: MCPeerID!) {
        NSLog("Lost peer \(peerID)")
    }
}