//
//  LocalNotification.swift
//  FishBowl
//
//  Created by Yasyf Mohamedali on 2015-04-11.
//  Copyright (c) 2015 com.fishbowl. All rights reserved.
//

import Foundation
import Localytics

class LocalNotification {
    static let database = Database()
    
    class func presentGeneric(message: String, title: String, viewController: UIViewController) {
        var alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil))
        viewController.presentViewController(alertController, animated: true, completion: nil)
    }
    
    class func sendGeneric(body: String) {
        var notification = UILocalNotification()
        notification.alertBody = body
        notification.userInfo = ["type": "generic"]
        notification.fireDate = NSDate(timeIntervalSinceNow: 1.0)
        notification.timeZone = NSTimeZone.defaultTimeZone()
        notification.soundName = UILocalNotificationDefaultSoundName
        UIApplication.sharedApplication().scheduleLocalNotification(notification)
        Localytics.tagEvent("ShowLocalNotification", attributes: ["reason": "generic"])
        
    }
    
    class func getDailyNotification() -> UILocalNotification? {
        let notifications = UIApplication.sharedApplication().scheduledLocalNotifications as! [UILocalNotification]
        for notification in notifications {
            if (notification.userInfo?["type"] as? String) == "daily" {
                return notification
            }
        }
        return nil
    }
    
    class func scheduleDaily() {
        var notification = getDailyNotification()
        if let oldNotif = notification {
            UIApplication.sharedApplication().cancelLocalNotification(oldNotif)
        } else  {
            let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
            let date = calendar?.dateBySettingHour(19, minute: 0, second: 0, ofDate: NSDate(), options: nil)
            
            var newNotification = UILocalNotification()
            newNotification.userInfo = ["type": "daily"]
            if (newNotification.respondsToSelector(Selector("setAlertTitle"))) {
                newNotification.alertTitle = "FishBowl Daily Digest"
            }
            newNotification.alertBody = "You didn't see anyone today. Go out there and make some friends!"
            newNotification.fireDate = date
            newNotification.timeZone = NSTimeZone.defaultTimeZone()
            newNotification.repeatInterval = NSCalendarUnit.CalendarUnitDay
            newNotification.soundName = UILocalNotificationDefaultSoundName
            newNotification.applicationIconBadgeNumber = UIApplication.sharedApplication().applicationIconBadgeNumber + 1
            notification = newNotification
        }
        if let notif = notification {
            notif.applicationIconBadgeNumber = UIApplication.sharedApplication().applicationIconBadgeNumber + 1
            let allInteractions = database.allInteractions(sorted: false)
            if let interactions = allInteractions {
                switch interactions.count {
                case 0:
                    notif.alertBody = "You didn't see anyone today. Go out there and make some friends!"
                case 1:
                    notif.alertBody = "View today's interaction with \(interactions.first!.person.f_name)!"
                default:
                    notif.alertBody = "View your interactions with \(interactions.first!.person.f_name) and \(interactions.count - 1) others!"
                }
            }
            UIApplication.sharedApplication().scheduleLocalNotification(notif)
        }
        
    }
}