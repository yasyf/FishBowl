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
import Localytics

class TimelineViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var table: UITableView!
    @IBOutlet weak var line: UIView!
    @IBOutlet weak var startText: UIView!
    
    let serviceType = "personlog-disc"
    let database = Database()
    var peer: Peer?
    var broadcaster: Broadcaster?
    var discoverer: Discoverer?
    var interactions = [Interaction]()
    let appDelegate = MyAppDelege.sharedInstance
    var dateFormatter = NSDateFormatter()
    let settings = Settings()
    var timer: NSTimer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let footer = UIView()
        footer.frame = CGRect(origin: CGPointZero, size: CGSize(width: 0, height: 25))
        table.tableFooterView = footer
        
        self.timer = NSTimer.scheduledTimerWithTimeInterval(1800, target: self, selector: Selector("updateInteractions"), userInfo: nil, repeats: true)
        
        dateFormatter.dateFormat = "hh:mm a"
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(false)
        
        Analytics.tagScreen("Timeline")

        if settings.isLoggedIn() && broadcaster == nil {
            broadcaster = appDelegate.broadcaster
            discoverer = appDelegate.discoverer
            peer = appDelegate.peer
        
            discoverer!.onPeer({(otherPeer: Peer) in
                Localytics.tagEvent("DiscoverPeer")
                self.peer!.recordInteraction(otherPeer, callback: {(interaction: Interaction?) in
                    if let inter = interaction {
                        self.updateInteractions()
                        otherPeer.processNewInteraction(inter, minCountForNotification: 2)
                        LocalNotification.scheduleDaily()
                    }
                })
            })
            
            discoverer!.onOtherUpdate(self.updateInteractions)
            
            broadcaster!.broadcast()
            discoverer!.discover()
        }

        updateInteractions()
        
        if discoverer?.lastState == .PoweredOff {
            LocalNotification.presentGeneric("Your phone relies on low-energy Bluetooth to find other phones. Please enable Bluetooth to prevent missing people!", title: "Bluetooth Is Disabled!", viewController: self)
        }
    }
    
    func updateInteractions() {
        if let newInteractions = database.allInteractions(sorted: true) {
            self.interactions = newInteractions
            Localytics.setValue(newInteractions.count, forProfileAttribute: "Interactions")
            dispatch_async(dispatch_get_main_queue(), {
                self.table.reloadData()
                self.line.hidden = (newInteractions.count == 0)
                self.startText.hidden = (newInteractions.count != 0)
            })
        }
    }
    
    // MARK: - Table view data source
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return interactions.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PersonCell", forIndexPath: indexPath) as! PersonCell
        
        let interaction = interactions[indexPath.row]
        let person = interaction.person
        
        cell.timeStamp.text = dateFormatter.stringFromDate(interaction.date)
        
        let photoURL = NSURL(string: person.photo_url)
        cell.profilePicture.sd_setImageWithURL(photoURL, placeholderImage: settings.unknownImage)
        
        cell.profilePicture.layer.borderColor = settings.lineColor
        cell.name.text = person.f_name
        
        if let isFriend = person.meta?["is_friend"] as? Bool {
            cell.facebookImage.hidden = !isFriend
        } else {
            let friendGraphRequest = FBSDKGraphRequest(graphPath: "/me/friends/\(person.fb_id)", parameters: nil)
            friendGraphRequest.startWithCompletionHandler({(_, result, error) in
                if let err = error {
                    CLS_LOG_SWIFT("friendGraphRequest.startWithCompletionHandler:error: \(err)")
                } else {
                    let friends = result.objectForKey("data") as! [NSMutableDictionary]
                    let isFriend = (friends.count != 0)
                    person.meta?.updateValue(isFriend, forKey: "is_friend")
                    cell.facebookImage.hidden = !(isFriend)
                }
            })
        }
        
        return cell
    }
 

    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let destination = segue.destinationViewController as? ProfileViewController {
            if let cell = sender as? PersonCell {
                if let index = table.indexPathForSelectedRow()?.row {
                    destination.interaction = interactions[index]
                    destination.isFriend = !cell.facebookImage.hidden
                }
            } else if let interaction = sender as? Interaction {
                destination.interaction = interaction
            }
        }
    }
}
