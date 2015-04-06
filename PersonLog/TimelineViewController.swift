//
//  TimelineViewController.swift
//  PersonLog
//
//  Created by Larry Zhang on 4/3/15.
//  Copyright (c) 2015 Yasyf Mohamedali. All rights reserved.
//

import UIKit
import MultipeerConnectivity
import SDWebImage

class TimelineViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var table: UITableView!
    
    let serviceType = "personlog-disc"
    let database = Database()
    var peer: Peer?
    var broadcaster: Broadcaster?
    var discoverer: Discoverer?
    var interactions = [Interaction]()
    let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
    var dateFormatter = NSDateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let footer = UIView()
        footer.frame = CGRect(origin: CGPointZero, size: CGSize(width: 0, height: 25))
        table.tableFooterView = footer
        self.updateInteractions()
        
        dateFormatter.dateFormat = "hh:mm A"
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(false)
        
        if Settings().isLoggedIn() && broadcaster == nil {
            broadcaster = appDelegate.broadcaster
            discoverer = appDelegate.discoverer
            peer = appDelegate.peer
        
            discoverer!.onPeer({(otherPeer: Peer) in
                self.peer!.recordInteraction(otherPeer, callback: {(interaction: Interaction?) in
                    if interaction != nil {
                        self.updateInteractions()
                    }
                })
            })
            broadcaster!.broadcast()
            discoverer!.discover()
        }
        updateInteractions()
    }
    
    func updateInteractions() {
        if let newInteractions = database.allInteractions(sorted: true) {
            interactions = newInteractions
            dispatch_async(dispatch_get_main_queue(), {
                self.table.reloadData()
            })
        }
    }
    
    // MARK: - Table view data source
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return interactions.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PersonCell", forIndexPath: indexPath) as PersonCell
        
        let interaction = interactions[indexPath.row]
        let person = interaction.person
        
        cell.timeStamp.text = dateFormatter.stringFromDate(interaction.date)
        
        let photoURL = NSURL(string: person.photo_url)!
        cell.profilePicture.sd_setImageWithURL(photoURL)
        
        let lineColor = UIColor(red: 231.0/255.0, green: 145.0/255.0, blue: 42.0/255.0, alpha: 1.0).CGColor
        cell.profilePicture.layer.borderColor = lineColor
        cell.name.text = person.f_name
        
        return cell
    }
 

    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "viewProfile" {
            if let destination = segue.destinationViewController as? ProfileView {
                if let index = table.indexPathForSelectedRow()?.row {
                    destination.person = interactions[index].person
                    destination.lat = interactions[index].lat
                    destination.lon = interactions[index].lon
                }
            }
        }
    }
}
