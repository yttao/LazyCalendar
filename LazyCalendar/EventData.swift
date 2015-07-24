//
//  EventData.swift
//  LazyCalendar
//
//  Created by Ying Tao on 7/24/15.
//  Copyright (c) 2015 Kim. All rights reserved.
//

import Foundation
import CoreData
import AddressBook

class EventData: NSManagedObject {
    @NSManaged var name: String?
    
    @NSManaged var dateStart: NSDate!
    @NSManaged var dateEnd: NSDate!
    
    @NSManaged var alarm: Bool
    @NSManaged var alarmTime: NSDate?
    
    @NSManaged var contacts: [Contact]
}

class Contact: NSManagedObject {
    @NSManaged var id: Int
    
    @NSManaged var firstName: String?
    @NSManaged var lastName: String?
}