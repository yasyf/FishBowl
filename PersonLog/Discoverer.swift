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
    var peers: [Peer] = []
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
    
    func process() {
        peers.filter({!$0.isProcessed}).map(Peer.process)
    }
    
    // MARK: - MCNearbyServiceBrowserDelegate
    
    func browser(browser: MCNearbyServiceBrowser!, foundPeer peerID: MCPeerID!, withDiscoveryInfo info: [NSObject : AnyObject]!) {
        NSLog("Found peer \(peerID.displayName)")
        let peer = Peer(peerID: peerID)
        peers.append(peer)
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