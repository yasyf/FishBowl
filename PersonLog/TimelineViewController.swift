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
    
    var people = [
        (time: "9:47 AM", image: UIImage(named: "jenn.png"), name: "Jenn"),
        (time: "10:23 AM", image: UIImage(named: "yasyf.png"), name: "Yasyf"),
        (time: "11:58 AM", image: UIImage(named: "david.png"), name: "David"),
        (time: "12:06 PM", image: UIImage(named: "rumya.png"), name: "Rumya"),
        (time: "1:34 PM", image: UIImage(named: "rose.png"), name: "Rose"),
        (time: "1:40 PM", image: UIImage(named: "tim.png"), name: "Tim"),
        (time: "2:11 PM", image: UIImage(named: "jaimie.png"), name: "Jaimie"),
        (time: "3:00 PM", image: UIImage(named: "emma.png"), name: "Emma"),
        (time: "4:29 PM", image: UIImage(named: "blake.png"), name: "Blake"),
    ]
    
    let serviceType = "personlog-disc"
    let peer = Peer()
    let broadcaster: Broadcaster
    let discoverer: Discoverer
    
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
        
        discoverer.onPeer({(otherPeer: Peer) in
            self.peer.recordInteraction(otherPeer, callback: {(interaction: Interaction) in
                //Timelineview.refresh
                //refresh queries DB for all people to show in timeline
                println(interaction)
            })
        })
    }
    
    // MARK: - Table view data source
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return people.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PersonCell", forIndexPath: indexPath) as PersonCell
        
        let person = people[indexPath.row]
        
        cell.timeStamp.text = person.time
        cell.profilePicture.image = person.image
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
