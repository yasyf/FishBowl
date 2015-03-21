//
//  PeerID.swift
//  PersonLog
//
//  Created by Yasyf Mohamedali on 2015-03-17.
//  Copyright (c) 2015 Yasyf Mohamedali. All rights reserved.
//

import Foundation
import MultipeerConnectivity

let settings = Settings()

class Peer: NSObject {
    let peerID: MCPeerID
    var isProcessed = false
    
    init(peerID: MCPeerID) {
        self.peerID = peerID
    }
    
    lazy var data: NSMutableDictionary = {
        //#TODO GET from server all available data
        return ["name": "#TODO"]
    }()
    
    func process() {
        isProcessed = true
        // #TODO create CoreData model, persist
    }
    
    class func defaultPeerID() -> MCPeerID {
        var uuid = settings.uuid()
        if uuid == nil {
            uuid = fetchNewID()
        }
        return MCPeerID(displayName: uuid)
    }
    
    class func fetchNewID() -> String {
        let data = ["name", "phone", "photo"].map(settings._string)
        // #TODO POST to server with data
        return "#TODO"
    }
}