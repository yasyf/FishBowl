//
//  Analytics.swift
//  FishBowl
//
//  Created by Yasyf Mohamedali on 2015-04-11.
//  Copyright (c) 2015 com.fishbowl. All rights reserved.
//

import Foundation
import Localytics
import Crashlytics

class Analytics {
    class func tagLaunchSource(launchOptions: [NSObject: AnyObject]?) {
        let launchMappings = [
            UIApplicationLaunchOptionsLocalNotificationKey: "Local Notification",
            UIApplicationLaunchOptionsRemoteNotificationKey: "Push Notification",
            UIApplicationLaunchOptionsLocationKey: "Location Event",
            UIApplicationLaunchOptionsBluetoothCentralsKey: "Bluetooth Central",
            UIApplicationLaunchOptionsBluetoothPeripheralsKey: "Bluetooth Peripheral",
        ]
        var launchMechanism = "Direct"
        if let options = launchOptions {
            for key in options.keys {
                if let mechanism = launchMappings[key as! String] {
                    launchMechanism = mechanism
                    break
                }
            }
        }
        Localytics.tagEvent("AppLaunch", attributes: ["mechanism": launchMechanism])
    }
    
    class func boolToString(bool: Bool?) -> String {
        if bool == nil {
            return "unknown"
        } else {
            if bool! {
                return "true"
            } else {
                return "false"
            }
        }
    }
    
    class func setValuesFromFacebook(result: [NSObject: AnyObject]) {
        let name = result["name"] as! String
        let id = result["id"] as! String
        Localytics.setValue(name, forIdentifier: "customer_name")
        Localytics.setCustomerId(id)
        Crashlytics.setUserName(name)
        Crashlytics.setUserIdentifier(id)
        if let email = result["email"] as? String {
            Localytics.setValue(email, forIdentifier: "email")
            Crashlytics.setUserEmail(email)
        }
        let fieldMapping = ["birthday": "Birthday", "hometown": "Hometown", "locale": "Locale", "timezone": "Timezone", "religion": "Religion", "political": "Political", "gender": "Gender"]
        for (key, mapping) in fieldMapping {
            if let value = result[key] as? String {
                Localytics.setValue(value, forProfileAttribute: mapping)
            }
        }
    }
    
    class func tagScreen(screen: String) {
        Localytics.tagScreen(screen)
        Crashlytics.setObjectValue(screen, forKey: "screen")
    }
}