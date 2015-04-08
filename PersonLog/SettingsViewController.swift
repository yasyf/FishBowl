//
//  SettingsViewController.swift
//  FishBowl
//
//  Created by Larry Zhang on 4/7/15.
//  Copyright (c) 2015 com.fishbowl. All rights reserved.
//

import UIKit
import SDWebImage

class SettingsViewController: UIViewController, FBSDKLoginButtonDelegate, UITextFieldDelegate {

    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var number: UITextField!
    @IBOutlet weak var twitter: UITextField!
    @IBOutlet weak var snapchat: UITextField!
    @IBOutlet weak var logoutView: FBSDKLoginButton!
    @IBOutlet weak var container: UIView!
    @IBOutlet weak var scrollView: UIScrollView!

    let settings = Settings()
    let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate

    override func viewDidLoad() {
        super.viewDidLoad()
        
        var dismissKeyboard = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        self.view.addGestureRecognizer(dismissKeyboard)
        
        number.delegate = self
        twitter.delegate = self
        snapchat.delegate = self

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
    
    func textFieldDidBeginEditing(textField: UITextField) {
        scrollView.setContentOffset(CGPointMake(0, 150), animated: true)
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        switch textField {
        case number:
            settings.setPhone(number.text)
        case twitter:
            settings.setTwitter(twitter.text)
        case snapchat:
            settings.setSnapchat(snapchat.text)
        default: ()
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func dismissKeyboard() {
        self.view.endEditing(true)
        scrollView.setContentOffset(CGPointMake(0, 0), animated: true)
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
