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

class PeerID {
    class func defaultPeerID() -> MCPeerID {
        var name = settings.name()
        if name == nil {
            name = UIDevice.currentDevice().name
        }
        return MCPeerID(displayName: name)
    }
}