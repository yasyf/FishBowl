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
    
    init(peerID: MCPeerID, serviceType: String) {
        self.peerID = peerID
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        super.init()
        browser.delegate = self
    }
    
    func discover() {
        browser.startBrowsingForPeers()
    }
    
    func kill() {
        browser.stopBrowsingForPeers()
    }
    
    func browser(browser: MCNearbyServiceBrowser!, foundPeer peerID: MCPeerID!, withDiscoveryInfo info: [NSObject : AnyObject]!) {
        NSLog("Found peer \(peerID) with discovery info \(info)")
    }
    
    func browser(browser: MCNearbyServiceBrowser!, lostPeer peerID: MCPeerID!) {
        NSLog("Lost peer \(peerID)")
    }
}