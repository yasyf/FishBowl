//
//  Settings.swift
//  PersonLog
//
//  Created by Yasyf Mohamedali on 2015-03-17.
//  Copyright (c) 2015 Yasyf Mohamedali. All rights reserved.
//

import Foundation

class Settings {
    let defaults = NSUserDefaults.standardUserDefaults()
    let fields = ["f_name", "l_name", "phone", "photo_url", "fb_id", "twitter", "snapchat"]
    let lineColor = UIColor(red: 231.0/255.0, green: 145.0/255.0, blue: 42.0/255.0, alpha: 1.0).CGColor
    
    func _string(key: String) -> String? {
        return defaults.stringForKey(key)
    }
    func firstName() -> String? {
        return _string("f_name")
    }
    func setFirstName(firstName: String) {
        defaults.setValue(firstName, forKey: "f_name")
    }
    func lastName() -> String? {
        return _string("l_name")
    }
    func setLastName(lastName: String) {
        defaults.setValue(lastName, forKey: "l_name")
    }
    func UUID() -> String? {
        return _string("uuid")
    }
    func setUUID(uuid: String) {
        defaults.setValue(uuid, forKey: "uuid")
    }
    func facebookID() -> String? {
        return _string("fb_id")
    }
    func setFacebookID(facebookID: String) {
        defaults.setValue(facebookID, forKey: "fb_id")
    }
    func photoURL() -> String? {
        return _string("photo_url")
    }
    func setphotoURL(photoURL: String) {
        defaults.setValue(photoURL, forKey: "photo_url")
    }
    func phone() -> String? {
        return _string("phone")
    }
    func setPhone(phone: String) {
        defaults.setValue(phone, forKey: "phone")
    }
    func twitter() -> String? {
        return _string("twitter")
    }
    func setTwitter(twitter: String) {
        defaults.setValue(twitter, forKey: "twitter")
    }
    func snapchat() -> String? {
        return _string("snapchat")
    }
    func setSnapchat(snapchat: String) {
        defaults.setValue(snapchat, forKey: "snapchat")
    }
    func isLoggedIn() -> Bool {
        return facebookID() != nil
    }
    func clear() {
        for field in fields {
            defaults.setValue(nil, forKey: field)
        }
    }
    func logout() {
        defaults.setValue(nil, forKey: "fb_id")
    }
}