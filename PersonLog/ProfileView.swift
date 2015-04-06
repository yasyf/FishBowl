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
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var fbButton: UIButton!
    @IBOutlet weak var map: MKMapView!
    @IBAction func fbLink(sender: AnyObject) {
        let url = NSURL(string: "http://facebook.com/\(person.fb_id)")
        UIApplication.sharedApplication().openURL(url!)
    }
    
    var person:Person!
    var lat:NSNumber!
    var lon:NSNumber!
    let settings = Settings()
    
    required init(coder aDecoder: NSCoder) {
        self.person = nil
        self.lat = nil
        self.lon = nil
        super.init(coder: aDecoder)
    }

    override init() {
        self.person = nil
        self.lat = nil
        self.lon = nil
        super.init()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        profilePicture.layer.borderColor = settings.lineColor
        
        let photoURL = NSURL(string: person.photo_url)
        let placeholderImage = UIImage(named: "unknown.png")
        profilePicture.sd_setImageWithURL(photoURL, placeholderImage: placeholderImage)
        
        name.text = "\(person.f_name) \(person.l_name)"
        
        map.delegate = self
        map.mapType = MKMapType.Standard

        let spanX = 0.002
        let spanY = 0.002
        
        let location = CLLocationCoordinate2DMake(lat as CLLocationDegrees, lon as CLLocationDegrees)
        var startRegion = MKCoordinateRegion(center: location, span: MKCoordinateSpanMake(spanX, spanY))
        map.setRegion(startRegion, animated: false)
        
        let pin = MKPointAnnotation()
        pin.setCoordinate(location)
        pin.title = "\(lat as CLLocationDegrees), \(lon as CLLocationDegrees)"
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
