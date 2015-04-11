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
import Localytics

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
    var isFriend: Bool?
    var isShowingAll = false
    var annotations = [MKPointAnnotation]()
    var mainPin = MKPointAnnotation()
    let settings = Settings()
    let api = API()
    let database = Database()
    var dateFormatter = NSDateFormatter()
    let messageViewController = MFMessageComposeViewController()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        Localytics.tagScreen("Profile")
        
        dateFormatter.dateFormat = "hh:mm a"

        self.title = "\(interaction.person.f_name)'s Profile"

        profilePicture.layer.borderColor = settings.lineColor

        let photoURL = NSURL(string: interaction.person.photo_url)
        profilePicture.sd_setImageWithURL(photoURL, placeholderImage: settings.unknownImage)

        name.text = "\(interaction.person.f_name) \(interaction.person.l_name)"

        facebookButton.setTitle("\(interaction.person.f_name)'s Facebook", forState: .Normal)

        let accessToken = FBSDKAccessToken.currentAccessToken().tokenString
        api.post("/friends/\(interaction.person.fb_id)/mutual", parameters: ["access_token": accessToken], success: {(data) in
            let mutualFriendCount = data["total_count"] as! Int
            Localytics.tagEvent("ViewProfile", attributes: ["mutual_friends": mutualFriendCount, "is_friend": Analytics.boolToString(self.isFriend)])
            dispatch_async(dispatch_get_main_queue(), {
                self.mutualFriendsLabel.text = "Mutual Friends: \(mutualFriendCount)"
            })
            }, failure: {(error, data) in
                println(error)
            }
        )
        
        if isFriend != nil {
            self.facebookImage.hidden = !isFriend!
        } else {
            let friendGraphRequest = FBSDKGraphRequest(graphPath: "/me/friends/\(interaction.person.fb_id)", parameters: nil)
            friendGraphRequest.startWithCompletionHandler({(_, result, error) in
                if let err = error {
                    println("Error: \(err)")
                } else {
                    let friends = result.objectForKey("data") as! [NSMutableDictionary]
                    if friends.count > 0 {
                        self.facebookImage.hidden = false
                    }
                }
            })
        }

        messageViewController.messageComposeDelegate = self

        map.delegate = self
        map.mapType = MKMapType.Standard

        let spanX = 0.002
        let spanY = 0.002

        let location = CLLocationCoordinate2DMake(interaction.lat as CLLocationDegrees, interaction.lon as CLLocationDegrees)
        var startRegion = MKCoordinateRegion(center: location, span: MKCoordinateSpanMake(spanX, spanY))
        map.setRegion(startRegion, animated: false)

        mainPin = pinFromInteraction(interaction)
        map.addAnnotation(mainPin)

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
    
    func pinFromInteraction(inter: Interaction) -> MKPointAnnotation {
        let pointAnnotation = MKPointAnnotation()
        let location = CLLocationCoordinate2DMake(inter.lat as CLLocationDegrees, inter.lon as CLLocationDegrees)
        pointAnnotation.coordinate = location
        pointAnnotation.title = dateFormatter.stringFromDate(inter.date)
        return pointAnnotation
    }
    
    func messageComposeViewController(controller: MFMessageComposeViewController!, didFinishWithResult result: MessageComposeResult) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func openFacebook(sender: AnyObject) {
        Localytics.tagEvent("SocialAction", attributes: ["type": "facebook"])
        let url = NSURL(string: "http://facebook.com/\(interaction.person.fb_id)")
        UIApplication.sharedApplication().openURL(url!)
    }
    
    @IBAction func showCurrentLocation(sender: AnyObject) {
        Localytics.tagEvent("MapAction", attributes: ["type": "current location"])
        self.map.showsUserLocation = true
        self.map.setUserTrackingMode(.Follow, animated: true)
    }
    
    @IBAction func showOtherInteractions(sender: AnyObject) {
        if isShowingAll {
            isShowingAll = false
            for annotation in annotations {
                if annotation != mainPin {
                    map.removeAnnotation(annotation)
                }
            }
            annotations = [mainPin]
        } else {
            Localytics.tagEvent("MapAction", attributes: ["type": "other interactions"])
            isShowingAll = true
            let predicate = NSPredicate(format: "(person.fb_id = %@)", interaction.person.fb_id)
            if let interactions = database.allInteractionsWithPredicate(false, predicate: predicate) {
                for inter in interactions {
                    if inter != interaction {
                        let pin = pinFromInteraction(inter)
                        annotations.append(pin)
                        map.addAnnotation(pin)
                    }
                }
            }
        }
    }

    @IBAction func openTwitter(sender: AnyObject) {
        Localytics.tagEvent("SocialAction", attributes: ["type": "twitter"])
        let url = NSURL(string: "twitter://user?screen_name=\(interaction.person.twitter!)")
        UIApplication.sharedApplication().openURL(url!)
    }

    @IBAction func openSnapchat(sender: AnyObject) {
        Localytics.tagEvent("SocialAction", attributes: ["type": "snapchat"])
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
        Localytics.tagEvent("SocialAction", attributes: ["type": "message"])
        messageViewController.recipients = [interaction.person.phone!]
        presentViewController(messageViewController, animated: true, completion: nil)
    }
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        if let pointAnnotation = annotation as? MKPointAnnotation {
            var annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: nil)
            annotationView.canShowCallout = true
            annotationView.draggable = false
            if annotation.title == mainPin.title {
                annotationView.pinColor = MKPinAnnotationColor.Red
                annotationView.animatesDrop = false
            } else {
                annotationView.pinColor = MKPinAnnotationColor.Purple
                annotationView.animatesDrop = true
            }
            return annotationView
        }
        return nil
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
