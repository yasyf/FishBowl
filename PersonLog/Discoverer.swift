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

class Discoverer: NSObject, MCNearbyServiceBrowserDelegate, CLLocationManagerDelegate {
    let serviceType: String
    let beaconID: NSUUID
    var browser: MCNearbyServiceBrowser?
    var beaconRegion: CLBeaconRegion?
    let peer: Peer
    var peers: [Peer] = []
    var peerCallbacks: [(Peer) -> Void] = []
    var isDiscovering: Bool = false
    var locManager = CLLocationManager()
    
    init(peer: Peer, serviceType: String, beaconID: NSUUID) {
        self.peer = peer
        self.serviceType = serviceType
        self.beaconID = beaconID
        super.init()
        self.locManager.delegate = self
    }
    
    func onPeer(callback: (Peer) -> Void) {
        peerCallbacks.append(callback)
        peers.map(callback)
    }
    
    func discover() {
        peer.onPeerID({(peerID: MCPeerID) in
            if self.browser == nil {
                self.browser = MCNearbyServiceBrowser(peer: peerID, serviceType: self.serviceType)
                self.browser!.delegate = self
            }
            if self.beaconRegion == nil {
                let beaconRegion = CLBeaconRegion(proximityUUID: self.beaconID, identifier: self.beaconID.UUIDString)
                beaconRegion.notifyEntryStateOnDisplay = true
                beaconRegion.notifyOnEntry = true
                self.beaconRegion = beaconRegion
            }
            self.browser!.startBrowsingForPeers()
            self.locManager.pausesLocationUpdatesAutomatically = false
            self.locManager.requestAlwaysAuthorization()
            self.locManager.startMonitoringForRegion(self.beaconRegion!)
            self.locManager.startRangingBeaconsInRegion(self.beaconRegion!)
            self.locManager.startUpdatingLocation()
            self.isDiscovering = true
        })
    }
    
    func kill() {
        isDiscovering = false
        browser?.stopBrowsingForPeers()
        self.locManager.stopUpdatingLocation()
        self.locManager.stopRangingBeaconsInRegion(self.beaconRegion?)
        self.locManager.stopMonitoringForRegion(self.beaconRegion?)
    }
    
    func didFindPeer(peerID: MCPeerID) {
        let peer = Peer(peerID: peerID)
        println("Found peer \(peerID.displayName)")
        peer.onData({(data: Dictionary<String, AnyObject>) in
            println(data)
        })
        peers.append(peer)
        for callback in peerCallbacks {
            callback(peer)
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [CLLocation]!) {
        self.peer.location = locations.last
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateToLocation newLocation: CLLocation!, fromLocation oldLocation: CLLocation!) {
        self.peer.location = newLocation
    }
    
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        println(error)
    }
    
    func locationManager(manager: CLLocationManager!, didEnterRegion region: CLRegion!) {
        println("didEnterRegion \(region)")
    }
    
    func locationManager(manager: CLLocationManager!, didExitRegion region: CLRegion!) {
        println("didExitRegion \(region)")
    }
    
    func locationManager(manager: CLLocationManager!, didRangeBeacons beacons: [AnyObject]!, inRegion region: CLBeaconRegion!) {
        println("didRangeBeacons \(beacons)")
    }
    
    func locationManager(manager: CLLocationManager!, didStartMonitoringForRegion region: CLRegion!) {
        println("didStartMonitoringForRegion \(region)")
    }
    
    // MARK: - MCNearbyServiceBrowserDelegate
    
    func browser(browser: MCNearbyServiceBrowser!, foundPeer peerID: MCPeerID!, withDiscoveryInfo info: [NSObject : AnyObject]!) {
        didFindPeer(peerID)
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