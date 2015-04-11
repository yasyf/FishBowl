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
import FormatterKit
import Localytics

let settings = Settings()
let api = API()
let database = Database()
let ordinalFormatter = TTTOrdinalNumberFormatter()

class Peer: NSObject {
    var peerID: MCPeerID?
    var isFetchingPeerID = false
    var isFetchingData = false
    var data: Dictionary<String, AnyObject>?
    var peerIDCallbacks: [(MCPeerID) -> Void] = []
    var beaconInRangeCallbacks: [(MCPeerID) -> Void] = []
    var dataCallbacks: [(Dictionary<String, AnyObject>) -> Void] = []
    let managedObjectContext = MyAppDelege.sharedInstance.managedObjectContext!
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
                        let message = data!["message"] as! String
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
        let data = settings.getLocalData()
        api.post("/register", parameters: data, success: {(response: Dictionary) in
                let uuid = response["uuid"] as! String
                println("Registered new user with uuid \(uuid)")
                self.peerID = MCPeerID(displayName: uuid)
                for completion in self.peerIDCallbacks {
                    completion(self.peerID!)
                }
                self.peerIDCallbacks = []
            }, failure: {(error: NSError, data: Dictionary<String, AnyObject>?) in
                if data != nil {
                    let message = data!["message"] as! String
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
        request.predicate = NSPredicate(format: "(fb_id = %@)", data["fb_id"] as! String)
        
        var personOptional: Person?
        
        var objects = managedObjectContext.executeFetchRequest(request, error: nil)
        if let results = objects {
            if results.count > 0 {
                personOptional = results[0] as? Person
            }
        }
        
        if personOptional == nil {
            personOptional = Person(entity: entityDescription!, insertIntoManagedObjectContext: managedObjectContext)
        }
        
        let person = personOptional!
        var error: NSError?
        
        let fields = ["f_name", "l_name", "phone", "photo_url", "fb_id", "twitter", "meta", "snapchat"]
        for field in fields {
            if let value: AnyObject = data[field] {
                person.setValue(value, forKey: field)
            }
        }
        
        if let twitter = person.twitter as NSString? {
            if twitter.containsString("@") {
                person.twitter = twitter.substringFromIndex(0)
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
            if let lon = location?.coordinate.longitude {
                interaction.lat = lat
                interaction.lon = lon
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
                self.newInteraction(person, otherPerson: otherPerson,callback: callback)
            })
        })
    }
    
    func processNewInteraction(interaction: Interaction, minCountForNotification: Int) {
        if UIApplication.sharedApplication().applicationState == UIApplicationState.Active {
            return
        }
        self.onPerson({(person: Person) in
            if let lastNotificationDate = person.last_notification {
                let dayAgo = NSDate(timeIntervalSinceNow: -86400)
                if lastNotificationDate.compare(dayAgo) == NSComparisonResult.OrderedDescending {
                    return
                }
            }
            let predicate = NSPredicate(format: "(person.fb_id = %@)", person.fb_id)
            if let count = database.allInteractionsWithPredicate(false, predicate: predicate)?.count {
                Localytics.tagEvent("Interaction", attributes: ["count": count])
                if count >= minCountForNotification {
                    person.last_notification = NSDate()
                    var error: NSError?
                    self.managedObjectContext.save(&error)
                    if let err = error {
                        println(err)
                    }
                    
                    let ordinal = ordinalFormatter.stringFromNumber(count)!
                    var notification = UILocalNotification()
                    let identifier = interaction.objectID.URIRepresentation().absoluteString!
                    notification.userInfo = ["identifier": identifier, "type": "frequency"]
                    notification.alertTitle = "\(person.f_name) \(person.l_name)"
                    notification.alertBody = "That's the \(ordinal) time you've seen \(person.f_name) today!"
                    notification.fireDate = NSDate(timeIntervalSinceNow: 1.0)
                    notification.timeZone = NSTimeZone.defaultTimeZone()
                    notification.soundName = UILocalNotificationDefaultSoundName
                    notification.applicationIconBadgeNumber = notification.applicationIconBadgeNumber + 1
                    UIApplication.sharedApplication().scheduleLocalNotification(notification)
                    Localytics.tagEvent("ShowLocalNotification", attributes: ["reason": "frequency", "frequency": count])
                }
            }
        })
    }
}