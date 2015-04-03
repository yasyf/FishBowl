//
//  Interaction.swift
//  PersonLog
//
//  Created by Yasyf Mohamedali on 2015-04-03.
//  Copyright (c) 2015 Yasyf Mohamedali. All rights reserved.
//

import Foundation
import CoreData

class Interaction: NSManagedObject {

    @NSManaged var date: NSDate
    @NSManaged var lat: NSNumber
    @NSManaged var lon: NSNumber
    @NSManaged var owner: PersonLog.Person
    @NSManaged var person: PersonLog.Person

}
