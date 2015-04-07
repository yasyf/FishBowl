//
//  LoginViewController.swift
//  FishBowl
//
//  Created by Larry Zhang on 4/5/15.
//  Copyright (c) 2015 com.fishbowl. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController, FBSDKLoginButtonDelegate {

    @IBOutlet var loginView: FBSDKLoginButton!
    let settings = Settings()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginView.readPermissions = ["public_profile", "user_friends"]
        loginView.delegate = self
    }

    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        if let err = error {
            println(err)
        } else if !result.isCancelled {
            self.setUserData({
                self.dismissViewControllerAnimated(false, completion: nil)
            })
        }
    }

    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        // settings.clear()
        // redirect to login page
    }

    func setUserData(completion: () -> Void) {
        let graphRequest = FBSDKGraphRequest(graphPath: "/me", parameters: nil)
        
        graphRequest.startWithCompletionHandler({(_, result, error) in
            if let err = error {
                println("Error: \(err)")
            } else {
                let fieldMap = ["first_name": "f_name", "last_name": "l_name", "id": "fb_id"]
                for (facebookField, settingField) in fieldMap {
                    let value = result.valueForKey(facebookField) as NSString
                    self.settings.defaults.setValue(value, forKey: settingField)
                }
                let userID = result.valueForKey("id") as NSString
                self.settings.setphotoURL("https://graph.facebook.com/\(userID)/picture?width=400&height=400")
            }
            completion()
        })
    }
}
