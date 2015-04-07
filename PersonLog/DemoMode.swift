//
//  DemoMode.swift
//  FishBowl
//
//  Created by Yasyf Mohamedali on 2015-04-07.
//  Copyright (c) 2015 com.fishbowl. All rights reserved.
//

import Foundation
import CoreData

class DemoMode: NSObject {
    let settings = Settings()
    let api = API()
    let managedObjectContext = (UIApplication.sharedApplication().delegate as AppDelegate).managedObjectContext!
    
    func deleteAll() -> Int {
        let entityDescription = NSEntityDescription.entityForName("Interaction", inManagedObjectContext: managedObjectContext)
        let fetchRequest = NSFetchRequest()
        var error: NSError?
        
        fetchRequest.entity = entityDescription
        fetchRequest.includesPropertyValues = false
        let allInteractions = managedObjectContext.executeFetchRequest(fetchRequest, error: &error)
        if let err = error {
            println(err)
        } else {
            if let interactions = allInteractions {
                let count = interactions.count
                for interaction in interactions {
                    managedObjectContext.deleteObject(interaction as NSManagedObject)
                }
                managedObjectContext.save(&error)
                return count
            }
        }
        return 0
    }
    
    func setHash(hash: String) {
        println("DemoMode: Set new hash of \(hash)")
        settings.defaults.setValue(hash, forKey: "freshness_hash")
    }
    
    func checkHash() {
        api.get("/demo/freshness", parameters: nil, success: {(data) in
                let newHash = data["freshness_hash"] as String
                if let oldHash = self.settings._string("freshness_hash") {
                    if oldHash != newHash {
                        self.setHash(newHash)
                        let count = self.deleteAll()
                        if count > 0 {
                            println("\(count) Interactions Deleted!")
                            (UIApplication.sharedApplication().delegate as AppDelegate).discoverer.triggerUpdate()
                        }
                        
                    }
                } else {
                    self.setHash(newHash)
                }
            }, failure: {(error, data) in
                    println(error)
                })
    }
    
    func startLooping() -> NSTimer {
        println("Starting in DemoMode")
        return NSTimer.scheduledTimerWithTimeInterval(5.0, target: self, selector: Selector("checkHash"), userInfo: nil, repeats: true)
    }
}