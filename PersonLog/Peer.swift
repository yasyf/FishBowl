//
//  PeerID.swift
//  PersonLog
//
//  Created by Yasyf Mohamedali on 2015-03-17.
//  Copyright (c) 2015 Yasyf Mohamedali. All rights reserved.
//

import Foundation
import MultipeerConnectivity
import CoreData
import CoreLocation

let settings = Settings()
let api: API = API()

class Peer: NSObject {
    var peerID: MCPeerID?
    var isFetchingPeerID = false
    var isFetchingData = false
    var data: Dictionary<String, AnyObject>?
    var peerIDCallbacks: [(MCPeerID) -> Void] = []
    var beaconInRangeCallbacks: [(MCPeerID) -> Void] = []
    var dataCallbacks: [(Dictionary<String, AnyObject>) -> Void] = []
    let managedObjectContext = (UIApplication.sharedApplication().delegate as AppDelegate).managedObjectContext!
    var location: CLLocation?
    
    override init(){
        super.init()
        self.peerID = defaultPeerID()
    }
    
    init(peerID: MCPeerID) {
        self.peerID = peerID
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
        var uuid = settings.UUID()
        if uuid == nil {
            peerIDCallbacks.append({(peerID: MCPeerID) in
                settings.setUUID(peerID.displayName)
            })
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
                        let message = data!["message"] as String
                        println("Error: \(message)")
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
        for key in ["f_name", "l_name", "phone", "photo_url", "fb_id", "twitter"] {
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
                    let message = data!["message"] as String
                    println("Error: \(message)")
                } else {
                    println("Error: \(error)")
                }

        })
    }
    
    func findOrCreatePerson(data: Dictionary<String, AnyObject>) -> Person {
        let entityDescription = NSEntityDescription.entityForName("Person", inManagedObjectContext: managedObjectContext)
        let request = NSFetchRequest()
        
        request.entity = entityDescription!
        request.predicate = NSPredicate(format: "(fb_id = %@)", data["fb_id"] as String)
        
        var objects = managedObjectContext.executeFetchRequest(request, error: nil)
        if let results = objects {
            if results.count > 0 {
                return results[0] as Person
            }
        }
        
        let person = Person(entity: entityDescription!, insertIntoManagedObjectContext: managedObjectContext)
        var error: NSError?
        
        let fields = ["f_name", "l_name", "phone", "photo_url", "fb_id", "twitter", "meta"]
        for field in fields {
            if let value: AnyObject = data[field] {
                person.setValue(value, forKey: field)
            }
        }
        
        managedObjectContext.save(&error)
        if let err = error {
            println(err)
        }
        return person
    }

    func newInteraction(person: Person, otherPerson: Person, callback: ((Interaction?) -> Void)?) {
        let entityDescription = NSEntityDescription.entityForName("Interaction", inManagedObjectContext: managedObjectContext)
        
        let date = NSDate()
        
        if let lastInteraction = otherPerson.visited.lastObject as? Interaction {
            let hourAgo = date.dateByAddingTimeInterval(-3600)
            if lastInteraction.date.compare(hourAgo) == NSComparisonResult.OrderedDescending  {
                println("Skipping interaction due to recent interaction")
                callback?(nil)
                return
            }
        }
        if person.fb_id == otherPerson.fb_id {
            println("Skipping interaction due to self interaction")
            callback?(nil)
            return
        }
        
        
        let interaction = Interaction(entity: entityDescription!, insertIntoManagedObjectContext: managedObjectContext)
        var error: NSError?
        
        interaction.owner = person
        interaction.person = otherPerson
        interaction.date = NSDate()

        if let lat = location?.coordinate.latitude {
            if let lon = location?.coordinate.latitude {
                interaction.lat = lat
                interaction.lon = lat
            }
        }
        
        self.managedObjectContext.save(&error)
        
        if let err = error {
            println(err)
            callback?(nil)
        } else {
            callback?(interaction)
        }
        
    }
    
    func onPerson(callback: (Person) -> Void) {
        onData({(data: Dictionary<String, AnyObject>) in
            let person = self.findOrCreatePerson(data)
            callback(person)
        })
    }
    
    func recordInteraction(other: Peer, callback: ((Interaction?) -> Void)?) {
        self.onPerson({(person: Person) in
            other.onPerson({(otherPerson: Person) in
                self.newInteraction(person, otherPerson: otherPerson, callback)
            })
        })
    }
}