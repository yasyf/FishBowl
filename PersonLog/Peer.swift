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

class Peer: NSObject, CLLocationManagerDelegate {
    var peerID: MCPeerID?
    var isFetchingPeerID = false
    var isFetchingData = false
    var data: Dictionary<String, AnyObject>?
    var peerIDCallbacks: [(MCPeerID) -> Void] = []
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
        request.predicate = NSPredicate(format: "(phone = %@)", data["phone"] as String)
        
        var objects = managedObjectContext.executeFetchRequest(request, error: nil)
        if let results = objects {
            if results.count > 0 {
                return results[0] as Person
            }
        }
        
        let person = Person(entity: entityDescription!, insertIntoManagedObjectContext: managedObjectContext)
        var error: NSError?
        
        let fields = ["name", "phone", "photo", "fb_id", "twitter", "meta"]
        for field in fields {
            person.setValue(data[field], forKey: field)
        }
        
        managedObjectContext.save(&error)
        if let err = error {
            println(err)
        }
        return person
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [CLLocation]!) {
        self.location = locations.last
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateToLocation newLocation: CLLocation!, fromLocation oldLocation: CLLocation!) {
        self.location = newLocation
    }
    
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        println(error)
    }

    func newInteraction(otherPerson: Person, callback: ((Interaction) -> Void)?) {
        let entityDescription = NSEntityDescription.entityForName("Interaction", inManagedObjectContext: managedObjectContext)
        let interaction = Interaction(entity: entityDescription!, insertIntoManagedObjectContext: managedObjectContext)
        var error: NSError?
        
        interaction.person = otherPerson

        if let lat = location?.coordinate.latitude {
            if let lon = location?.coordinate.latitude {
                interaction.lat = lat
                interaction.lon = lat
            }
        }
        
        onPerson({(person: Person) in
            interaction.owner = person
            self.managedObjectContext.save(&error)
            if let err = error {
                println(err)
            }
            callback?(interaction)
        })
    }
    
    func onPerson(callback: (Person) -> Void) {
        onData({(data: Dictionary<String, AnyObject>) in
            let person = self.findOrCreatePerson(data)
            callback(person)
        })
    }
    
    func recordInteraction(other: Peer, callback: ((Interaction) -> Void)?) {
        other.onPerson({(otherPerson: Person) in
            self.newInteraction(otherPerson, callback)
        })
    }
}