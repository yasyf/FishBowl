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
    let serviceType: String
    var browser: MCNearbyServiceBrowser?
    let peer: Peer
    var peers: [Peer] = []
    var isDiscovering: Bool = false
    
    init(peer: Peer, serviceType: String) {
        self.peer = peer
        self.serviceType = serviceType
        super.init()
    }
    
    
    func discover() {
        peer.onPeerID({(peerID: MCPeerID) in
            if self.browser == nil {
                self.browser = MCNearbyServiceBrowser(peer: peerID, serviceType: self.serviceType)
                self.browser!.delegate = self
            }
            self.browser!.startBrowsingForPeers()
            self.isDiscovering = true
        })
    }
    
    func kill() {
        isDiscovering = false
        browser?.stopBrowsingForPeers()
    }
    
    func process() {
        peers.filter({!$0.isProcessed}).map(Peer.process)
    }
    
    // MARK: - MCNearbyServiceBrowserDelegate
    
    func browser(browser: MCNearbyServiceBrowser!, foundPeer peerID: MCPeerID!, withDiscoveryInfo info: [NSObject : AnyObject]!) {
        let peer = Peer(peerID: peerID)
        println("Found peer \(peerID.displayName)")
        peer.onData({(data: Dictionary<String, AnyObject>) in
            println(data)
        })
        peers.append(peer)
    }
    
    func browser(browser: MCNearbyServiceBrowser!, lostPeer peerID: MCPeerID!) {
        println("Lost peer \(peerID)")
        for (i, peer) in enumerate(peers) {
            if peer.peerID == peerID {
                peers.removeAtIndex(i)
                break
            }
        }
    }
}