//
//  ProfileView.swift
//  FishBowl
//
//  Created by Larry Zhang on 4/5/15.
//  Copyright (c) 2015 com.fishbowl. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import SDWebImage

class ProfileView: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var facebookImage: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var fbButton: UIButton!
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var mutualFriendsLabel: UILabel!
    @IBAction func fbLink(sender: AnyObject) {
        let url = NSURL(string: "http://facebook.com/\(interaction.person.fb_id)")
        UIApplication.sharedApplication().openURL(url!)
    }
    @IBAction func currentLocation(sender: AnyObject) {
        var locManager = CLLocationManager()
        locManager.delegate = self
        self.map.showsUserLocation = true
        self.map.setUserTrackingMode(.Follow, animated: true)
    }
    
    var interaction: Interaction!
    var isFriend: Bool!
    let settings = Settings()
    let api = API()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "\(interaction.person.f_name)'s Profile"
        
        profilePicture.layer.borderColor = settings.lineColor
        
        let photoURL = NSURL(string: interaction.person.photo_url)
        profilePicture.sd_setImageWithURL(photoURL, placeholderImage: settings.unknownImage)

        facebookImage.hidden = !isFriend!
        
        name.text = "\(interaction.person.f_name) \(interaction.person.l_name)"
        
        fbButton.setTitle("\(interaction.person.f_name)'s Facebook", forState: .Normal)

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
