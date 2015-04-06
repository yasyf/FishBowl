//
//  ProfileView.swift
//  FishBowl
//
//  Created by Larry Zhang on 4/5/15.
//  Copyright (c) 2015 com.fishbowl. All rights reserved.
//

import UIKit
import MapKit

class ProfileView: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var fbButton: UIButton!
    @IBOutlet weak var map: MKMapView!
    @IBAction func fbLink(sender: AnyObject) {
        let url = NSURL(string: "fb://profile/app_scoped_user_id/\(person!.fb_id)")
        UIApplication.sharedApplication().openURL(url!)
    }
    
    var person:Person?
    var location:CLLocationCoordinate2D?
    
    required init(coder aDecoder: NSCoder) {
        self.person = nil
        self.location = nil
        super.init(coder: aDecoder)
    }

    override init() {
        self.person = nil
        self.location = nil
        super.init()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let lineColor = UIColor(red: 231.0/255.0, green: 145.0/255.0, blue: 42.0/255.0, alpha: 1.0).CGColor
        profilePicture.layer.borderColor = lineColor
        
        name.text = "\(person!.f_name) \(person!.l_name)"
        
        map.delegate = self
        map.mapType = MKMapType.Standard

        let spanX = 0.002
        let spanY = 0.002
        
        let lat = 42.358040 as CLLocationDegrees
        let lon = -71.093917 as CLLocationDegrees
        let test = CLLocationCoordinate2DMake(lat, lon)
        var startRegion = MKCoordinateRegion(center: test, span: MKCoordinateSpanMake(spanX, spanY))
//        var startRegion = MKCoordinateRegion(center: location!, span: MKCoordinateSpanMake(spanX, spanY))
        map.setRegion(startRegion, animated: false)
        
        let pin = MKPointAnnotation()
        pin.setCoordinate(test)
//        pin.setCoordinate(location!)
        map.addAnnotation(pin)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
