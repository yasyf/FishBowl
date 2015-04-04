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
    let peer = Peer()
    let database = Database()
    let broadcaster: Broadcaster
    let discoverer: Discoverer
    var interactions = [Interaction]()
    
    override init() {
        broadcaster = Broadcaster(peer: peer, serviceType: serviceType)
        discoverer = Discoverer(peer: peer, serviceType: serviceType)
        super.init()
    }
    
    required init(coder aDecoder: NSCoder) {
        broadcaster = Broadcaster(peer: peer, serviceType: serviceType)
        discoverer = Discoverer(peer: peer, serviceType: serviceType)
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let footer = UIView()
        footer.frame = CGRect(origin: CGPointZero, size: CGSize(width: 0, height: 25))
        table.tableFooterView = footer
        
        broadcaster.broadcast()
        discoverer.discover()
        updateInteractions()
        println(interactions)
        
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
        if let newInteractions = database.allInteractions() {
            interactions = newInteractions
        }
//        dispatch_async(dispatch_get_main_queue(), {
//            self.table.reloadData()
//        })
    }
    
    // MARK: - Table view data source
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return interactions.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PersonCell", forIndexPath: indexPath) as PersonCell
        
        let interaction = interactions[indexPath.row]
        let person = interaction.person
        
        println(interaction)
        println(person.name)
        println(interaction.date)
        println(interaction.date.description)
        
        cell.timeStamp.text = interaction.date.description
        cell.profilePicture.image = UIImage(named: "yasyf.png")
        let lineColor = UIColor(red: 231.0/255.0, green: 145.0/255.0, blue: 42.0/255.0, alpha: 1.0).CGColor
        cell.profilePicture.layer.borderColor = lineColor
        cell.name.text = person.name
        
        return cell
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
