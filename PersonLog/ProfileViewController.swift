//
//  ProfileViewController.swift
//  FishBowl
//
//  Created by Larry Zhang on 4/5/15.
//  Copyright (c) 2015 com.fishbowl. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import SDWebImage
import MessageUI

class ProfileViewController: UIViewController, MKMapViewDelegate, MFMessageComposeViewControllerDelegate {

    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var facebookImage: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var facebookButton: UIButton!
    @IBOutlet weak var messageButton: UIButton!
    @IBOutlet weak var twitterButton: UIButton!
    @IBOutlet weak var snapchatButton: UIButton!
    @IBOutlet weak var container: UIView!
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var mutualFriendsLabel: UILabel!

    var interaction: Interaction!
    let settings = Settings()
    let api = API()
    let messageViewController = MFMessageComposeViewController()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "\(interaction.person.f_name)'s Profile"

        profilePicture.layer.borderColor = settings.lineColor

        let photoURL = NSURL(string: interaction.person.photo_url)
        profilePicture.sd_setImageWithURL(photoURL, placeholderImage: settings.unknownImage)

        name.text = "\(interaction.person.f_name) \(interaction.person.l_name)"

        facebookButton.setTitle("\(interaction.person.f_name)'s Facebook", forState: .Normal)

        let accessToken = FBSDKAccessToken.currentAccessToken().tokenString
        api.post("/friends/\(interaction.person.fb_id)/mutual", parameters: ["access_token": accessToken], success: {(data) in
            let mutualFriendCount = data["total_count"] as Int
            dispatch_async(dispatch_get_main_queue(), {
                self.mutualFriendsLabel.text = "Mutual Friends: \(mutualFriendCount)"
            })
            }, failure: {(error, data) in
                println(error)
            }
        )
        
        let friendGraphRequest = FBSDKGraphRequest(graphPath: "/me/friends/\(interaction.person.fb_id)", parameters: nil)
        friendGraphRequest.startWithCompletionHandler({(_, result, error) in
            if let err = error {
                println("Error: \(err)")
            } else {
                let friends = result.objectForKey("data") as [NSMutableDictionary]
                if friends.count > 0 {
                    self.facebookImage.hidden = false
                }
            }
        })
        
        messageViewController.messageComposeDelegate = self

        map.delegate = self
        map.mapType = MKMapType.Standard

        let spanX = 0.002
        let spanY = 0.002

        let location = CLLocationCoordinate2DMake(interaction.lat as CLLocationDegrees, interaction.lon as CLLocationDegrees)
        var startRegion = MKCoordinateRegion(center: location, span: MKCoordinateSpanMake(spanX, spanY))
        map.setRegion(startRegion, animated: false)

        let pin = MKPointAnnotation()
        pin.setCoordinate(location)
        map.addAnnotation(pin)

        // Buttons
        var bottomButton = facebookButton
        
        if let phone = interaction.person.phone {
            if phone != "" && MFMessageComposeViewController.canSendText() {
                messageButton.setTitle("iMessage \(interaction.person.f_name)", forState: .Normal)
                messageButton.hidden = false
                container.addConstraint(NSLayoutConstraint(item: bottomButton, attribute: .Bottom, relatedBy: .Equal, toItem: messageButton, attribute: .Top, multiplier: 1.0, constant: -15))
                bottomButton = messageButton
            }
        }
        
        if let twitter = interaction.person.twitter {
            if twitter != "" {
                twitterButton.setTitle("@\(twitter) on Twitter", forState: .Normal)
                twitterButton.hidden = false
                container.addConstraint(NSLayoutConstraint(item: bottomButton, attribute: .Bottom, relatedBy: .Equal, toItem: twitterButton, attribute: .Top, multiplier: 1.0, constant: -15))
                bottomButton = twitterButton
            }
        }
        
        if let snapchat = interaction.person.snapchat {
            if snapchat != "" {
                snapchatButton.setTitle("\(snapchat) on Snapchat", forState: .Normal)
                snapchatButton.hidden = false
                container.addConstraint(NSLayoutConstraint(item: bottomButton, attribute: .Bottom, relatedBy: .Equal, toItem: snapchatButton, attribute: .Top, multiplier: 1.0, constant: -15))
                bottomButton = snapchatButton
            }
        }

        container.addConstraint(NSLayoutConstraint(item: bottomButton, attribute: .Bottom, relatedBy: .Equal, toItem: container, attribute: .Bottom, multiplier: 1.0, constant: -20))
    }
    
    func messageComposeViewController(controller: MFMessageComposeViewController!, didFinishWithResult result: MessageComposeResult) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func openFacebook(sender: AnyObject) {
        let url = NSURL(string: "http://facebook.com/\(interaction.person.fb_id)")
        UIApplication.sharedApplication().openURL(url!)
    }
    @IBAction func showCurrentLocation(sender: AnyObject) {
        self.map.showsUserLocation = true
        self.map.setUserTrackingMode(.Follow, animated: true)
    }

    @IBAction func openTwitter(sender: AnyObject) {
        let url = NSURL(string: "twitter://user?screen_name=\(interaction.person.twitter!)")
        UIApplication.sharedApplication().openURL(url!)
    }

    @IBAction func openSnapchat(sender: AnyObject) {
        let snapchat = interaction.person.snapchat!
        let url = NSURL(string: "snapchat://?u=\(snapchat)")
        UIPasteboard.generalPasteboard().string = snapchat
        var alertController = UIAlertController(title: "Snapchat \(interaction.person.f_name)", message: "\(interaction.person.f_name)'s Snapchat username has been copied to your clipboard!", preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .Default, handler: {action in
            UIApplication.sharedApplication().openURL(url!)
            return
        }))
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    @IBAction func openMessageView(sender: AnyObject) {
        messageViewController.recipients = [interaction.person.phone!]
        presentViewController(messageViewController, animated: true, completion: nil)
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
