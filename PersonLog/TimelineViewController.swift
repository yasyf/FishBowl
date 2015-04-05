//
//  TimelineViewController.swift
//  PersonLog
//
//  Created by Larry Zhang on 4/3/15.
//  Copyright (c) 2015 Yasyf Mohamedali. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class TimelineViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var table: UITableView!
    
    let serviceType = "personlog-disc"
    let database = Database()
    let peer = (UIApplication.sharedApplication().delegate as AppDelegate).peer
    let broadcaster = (UIApplication.sharedApplication().delegate as AppDelegate).broadcaster
    let discoverer = (UIApplication.sharedApplication().delegate as AppDelegate).discoverer
    var interactions = [Interaction]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let footer = UIView()
        footer.frame = CGRect(origin: CGPointZero, size: CGSize(width: 0, height: 25))
        table.tableFooterView = footer
        
        broadcaster.broadcast()
        discoverer.discover()
        updateInteractions()
        println("starting")
        
        discoverer.onPeer({(otherPeer: Peer) in
            self.peer.recordInteraction(otherPeer, callback: {(interaction: Interaction) in
                self.updateInteractions()
                dispatch_async(dispatch_get_main_queue(), {
                    self.table.reloadData()
                })
            })
        })
    }
    
    func updateInteractions() {
        if let newInteractions = database.allInteractions(sorted: true) {
            interactions = newInteractions
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
        
        cell.timeStamp.text = interaction.date.description
        cell.profilePicture.image = UIImage(named: "yasyf.png")
        let lineColor = UIColor(red: 231.0/255.0, green: 145.0/255.0, blue: 42.0/255.0, alpha: 1.0).CGColor
        cell.profilePicture.layer.borderColor = lineColor
        cell.name.text = person.f_name
        
        return cell
    }
 
    /*
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    }
    */

}
