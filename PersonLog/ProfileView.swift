//
//  ProfileView.swift
//  FishBowl
//
//  Created by Larry Zhang on 4/5/15.
//  Copyright (c) 2015 com.fishbowl. All rights reserved.
//

import UIKit
import MapKit
import SDWebImage

class ProfileView: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var facebookImage: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var fbButton: UIButton!
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var mutualFriendsLabel: UILabel!
    @IBAction func fbLink(sender: AnyObject) {
        let url = NSURL(string: "http://facebook.com/\(person.fb_id)")
        UIApplication.sharedApplication().openURL(url!)
    }
    
    var person:Person!
    var lat:NSNumber!
    var lon:NSNumber!
    var friend:Bool!
    let settings = Settings()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "\(person.f_name)'s Profile"
        
        profilePicture.layer.borderColor = settings.lineColor
        
        let photoURL = NSURL(string: person.photo_url)
        let placeholderImage = UIImage(named: "unknown.png")
        profilePicture.sd_setImageWithURL(photoURL, placeholderImage: placeholderImage)

        if friend! {
            facebookImage.hidden = false
        }
        
        name.text = "\(person.f_name) \(person.l_name)"
        
        fbButton.setTitle("Visit \(person.f_name)'s Facebook", forState: UIControlState.Normal)

//        let mutualFriendGraphRequest = FBSDKGraphRequest(graphPath: "/\(person.fb_id)", parameters: ["fields": "context.fields(mutual_friends)"])
//        mutualFriendGraphRequest.startWithCompletionHandler({(_, result, error) in
//            let summary = result.objectForKey("summary") as NSMutableDictionary
//            let mutualFriendCount = summary.objectForKey("total_count") as Int
//            dispatch_async(dispatch_get_main_queue(), {
//                self.mutualFriendsLabel.text = "Mutual Friends: \(mutualFriendCount)"
//            })
//        })
        
        map.delegate = self
        map.mapType = MKMapType.Standard

        let spanX = 0.002
        let spanY = 0.002
        
        let location = CLLocationCoordinate2DMake(lat as CLLocationDegrees, lon as CLLocationDegrees)
        var startRegion = MKCoordinateRegion(center: location, span: MKCoordinateSpanMake(spanX, spanY))
        map.setRegion(startRegion, animated: false)
        
        let pin = MKPointAnnotation()
        pin.setCoordinate(location)
        map.addAnnotation(pin)
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
