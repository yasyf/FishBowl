//
//  LoginViewController.swift
//  FishBowl
//
//  Created by Larry Zhang on 4/5/15.
//  Copyright (c) 2015 com.fishbowl. All rights reserved.
//

import UIKit
import Localytics

class LoginViewController: UIViewController, FBSDKLoginButtonDelegate {

    @IBOutlet var loginView: FBSDKLoginButton!
    let settings = Settings()
    let permissions = MyAppDelege.sharedInstance.facebookPermissions + MyAppDelege.sharedInstance.additionalFacebookPermissions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginView.readPermissions = permissions
        loginView.delegate = self
        
        if FBSDKAccessToken.currentAccessToken() != nil {
            FBSDKLoginManager().logInWithReadPermissions(permissions, handler: loginHandler)
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        Analytics.tagScreen("Login")
    }
    
    func loginHandler(result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        if let err = error {
            CLS_LOG_SWIFT("loginButton:didCompleteWithResult:error: %@", [err])
        }
        else {
            if result.isCancelled {
                Localytics.tagEvent("Login", attributes: ["type": "facebook", "cancelled": true])
            } else {
                Localytics.tagEvent("Login", attributes: ["type": "facebook", "cancelled": false])
                FBSDKProfile.enableUpdatesOnAccessTokenChange(true)
                self.setUserData({
                    if self.settings.isDoneSetup() {
                        self.performSegueWithIdentifier("login", sender: nil)
                    } else {
                        self.performSegueWithIdentifier("setup", sender: nil)
                    }
                })
            }
        }
    }

    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        loginHandler(result, error: error)
    }

    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        NSException(name: "FBSDKLoginButtonDelegate", reason: "Invalid call to loginButtonDidLogOut", userInfo: nil).raise()
    }

    func setUserData(completion: () -> Void) {
        let graphRequest = FBSDKGraphRequest(graphPath: "/me", parameters: nil)
        
        graphRequest.startWithCompletionHandler({(_, result, error) in
            if let err = error {
                CLS_LOG_SWIFT("Error: \(err)")
            } else {
                let fieldMap = ["first_name": "f_name", "last_name": "l_name", "id": "fb_id"]
                for (facebookField, settingField) in fieldMap {
                    let value = result[facebookField] as! NSString
                    self.settings.defaults.setValue(value, forKey: settingField)
                }
                let userID = result["id"] as! NSString
                self.settings.setphotoURL("https://graph.facebook.com/\(userID)/picture?width=400&height=400")
                Analytics.setValuesFromFacebook(result as! [NSObject: AnyObject])
            }
            completion()
        })
    }
}
