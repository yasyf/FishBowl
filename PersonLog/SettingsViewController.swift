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
    @IBOutlet weak var number: UILabel!
    @IBOutlet weak var twitter: UILabel!
    @IBOutlet weak var snapchat: UILabel!
    @IBOutlet weak var logoutView: FBSDKLoginButton!

    let settings = Settings()
    let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
    var broadcaster: Broadcaster?
    var discoverer: Discoverer?

    override func viewDidLoad() {
        super.viewDidLoad()

        profilePicture.layer.borderColor = settings.lineColor!
        
        let photoURL = NSURL(string: settings.photoURL()!)
        profilePicture.sd_setImageWithURL(photoURL, placeholderImage: UIImage(named: "Unknown.png"))
        
        name.text = "\(settings.firstName()!) \(settings.lastName()!)"
        if let phone = settings.phone() {
            number.text = phone
        }
        if let handle = settings.twitter() {
            twitter.text = handle
        }
        if let snap = settings.snapchat() {
            snapchat.text = snap
        }
        
        logoutView.readPermissions = ["public_profile", "user_friends"]
        logoutView.delegate = self
    }
    
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        if settings.isLoggedIn() && broadcaster == nil {
            broadcaster = appDelegate.broadcaster
            discoverer = appDelegate.discoverer
        }
        broadcaster!.kill()
        discoverer!.kill()
        
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
