//
//  Person.swift
//  PersonLog
//
//  Created by Yasyf Mohamedali on 2015-04-03.
//  Copyright (c) 2015 Yasyf Mohamedali. All rights reserved.
//

import Foundation
import CoreData

class Person: NSManagedObject {

    @NSManaged var fb_id: String
    @NSManaged var meta: AnyObject
    @NSManaged var f_name: String
    @NSManaged var phone: String
    @NSManaged var photo_url: String
    @NSManaged var twitter: String
    @NSManaged var l_name: String
    @NSManaged var interactions: NSOrderedSet
    @NSManaged var visited: NSOrderedSet


}
