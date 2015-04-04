//
//  Database.swift
//  PersonLog
//
//  Created by Yasyf Mohamedali on 2015-04-03.
//  Copyright (c) 2015 Yasyf Mohamedali. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class Database: NSObject {
    let managedObjectContext = (UIApplication.sharedApplication().delegate as AppDelegate).managedObjectContext!
    
    func allInteractions(sorted: Bool = true) -> [Interaction]? {
        let entityDescription = NSEntityDescription.entityForName("Interaction", inManagedObjectContext: managedObjectContext)
        let interaction = Interaction(entity: entityDescription!, insertIntoManagedObjectContext: managedObjectContext)
        
        let request = NSFetchRequest()
        var error: NSError?
        request.entity = entityDescription!
        if sorted {
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        }
        
        let objects = managedObjectContext.executeFetchRequest(request, error: &error)
        if let err = error {
            println(err)
            return nil
        } else {
            println(objects!.count)
            println(objects![0] as Interaction)
            
            return objects as? [Interaction]
        }
    }
}