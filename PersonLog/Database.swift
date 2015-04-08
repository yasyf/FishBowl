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
    let managedObjectContext = MyAppDelege.sharedInstance.managedObjectContext!
    
    func allInteractionsWithPredicate(sorted: Bool, predicate: NSPredicate?) -> [Interaction]? {
        let entityDescription = NSEntityDescription.entityForName("Interaction", inManagedObjectContext: managedObjectContext)
        let request = NSFetchRequest()
        var error: NSError?
        request.entity = entityDescription!
        if sorted {
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        }
        if let pred = predicate {
            request.predicate = predicate
        }
        
        let objects = managedObjectContext.executeFetchRequest(request, error: &error)
        if let err = error {
            println(err)
            return nil
        } else {
            return objects as? [Interaction]
        }
    }
    
    func allInteractions(sorted: Bool = true) -> [Interaction]? {
        return allInteractionsWithPredicate(sorted, predicate: nil)
    }
}