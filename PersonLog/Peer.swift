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
let api: API = API()

class Peer: NSObject {
    var peerID: MCPeerID?
    var isProcessed = false
    var isFetchingPeerID = false
    var isFetchingData = false
    var data: Dictionary<String, AnyObject>?
    var peerIDCallbacks: [(MCPeerID) -> Void] = []
    var dataCallbacks: [(Dictionary<String, AnyObject>) -> Void] = []
    
    override init(){
        super.init()
        self.peerID = defaultPeerID()
    }
    
    init(peerID: MCPeerID) {
        self.peerID = peerID
    }
    
    func process() {
        isProcessed = true
        // #TODO create CoreData model, persist
    }
    
    func onData(completion: (Dictionary<String, AnyObject> -> Void)) {
        if data != nil {
            completion(data!)
        } else {
            dataCallbacks.append(completion)
            fetchData()
        }
    }
    
    func onPeerID(completion: (MCPeerID) -> Void) {
        if peerID != nil {
            completion(peerID!)
        } else {
            peerIDCallbacks.append(completion)
            fetchNewID()
        }
    }
    
    func defaultPeerID() -> MCPeerID? {
        var uuid = settings.uuid()
        if uuid == nil {
            fetchNewID()
            return nil
        } else {
            return MCPeerID(displayName: uuid)
        }
    }
    
    func fetchData() {
        if isFetchingData {
            return
        } else {
            isFetchingData = true
        }
        onPeerID({(peerID: MCPeerID) in
            let uuid = peerID.displayName
            api.get("/\(uuid)", parameters: nil, success: {(response: Dictionary) in
                    self.data = response["user"] as? Dictionary
                    for completion in self.dataCallbacks {
                        completion(self.data!)
                    }
                    self.dataCallbacks = []
                }, failure: {(error: NSError, data: Dictionary<String, AnyObject>?) in
                    if data != nil {
                        println("Error: \(data)")
                    } else {
                        println("Error: \(error)")
                    }
                })
        })
    }
    
    func fetchNewID() {
        if isFetchingPeerID {
            return
        } else {
            isFetchingPeerID = true
        }
        var data = [String:String]()
        for key in ["name", "phone", "photo"] {
            data[key] = settings._string(key)
        }
        api.post("/register", parameters: data, success: {(response: Dictionary) in
                let uuid = response["uuid"] as String
                println("Registered new user with uuid \(uuid)")
                self.peerID = MCPeerID(displayName: uuid)
                for completion in self.peerIDCallbacks {
                    completion(self.peerID!)
                }
                self.peerIDCallbacks = []
            }, failure: {(error: NSError, data: Dictionary<String, AnyObject>?) in
                if data != nil {
                    println("Error: \(data)")
                } else {
                    println("Error: \(error)")
                }

        })
    }
}