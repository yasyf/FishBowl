//
//  SettingsViewController.swift
//  FishBowl
//
//  Created by Larry Zhang on 4/7/15.
//  Copyright (c) 2015 com.fishbowl. All rights reserved.
//

import UIKit
import SDWebImage

class SettingsViewController: UIViewController, FBSDKLoginButtonDelegate {

    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var number: UITextField!
    @IBOutlet weak var twitter: UITextField!
    @IBOutlet weak var snapchat: UITextField!
    @IBOutlet weak var logoutView: FBSDKLoginButton!

    let settings = Settings()
    let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate

    override func viewDidLoad() {
        super.viewDidLoad()

        profilePicture.layer.borderColor = settings.lineColor
        
        if let photoUrl = settings.photoURL() {
            profilePicture.sd_setImageWithURL(NSURL(string: photoUrl), placeholderImage: settings.unknownImage)
        }
        
        name.text = "\(settings.firstName()!) \(settings.lastName()!)"
        
        if let phone = settings.phone() {
            number.text = phone
        }
        if let twitterHandle = settings.twitter() {
            twitter.text = twitterHandle
        }
        if let snapchatUsername = settings.snapchat() {
            snapchat.text = snapchatUsername
        }
        
        logoutView.delegate = self
    }
    
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        NSException(name: "FBSDKLoginButtonDelegate", reason: "Invalid call to loginButton:didCompleteWithResult", userInfo: nil).raise()
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        if settings.isLoggedIn() {
            appDelegate.broadcaster.kill()
            appDelegate.discoverer.kill()
        }
        settings.logout()
        self.performSegueWithIdentifier("logout", sender: nil)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
