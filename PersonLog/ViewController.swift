//
//  ViewController.swift
//  PersonLog
//
//  Created by Yasyf Mohamedali on 2015-03-17.
//  Copyright (c) 2015 Yasyf Mohamedali. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ViewController: UIViewController {
    @IBOutlet weak var advertisingButton: UIButton!
    @IBOutlet weak var discoveringButton: UIButton!
    @IBOutlet weak var peerIDLabel: UILabel!
    @IBOutlet weak var textLogView: UITextView!
    @IBOutlet weak var numInteractionsLabel: UILabel!
    
    let serviceType = "personlog-disc"
    let peer = Peer()
    let database = Database()
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
        if let allInteractions = database.allInteractions(sorted: true) {
            numInteractionsLabel.text = "Saved Interactions: \(allInteractions.count)"
        }
        peer.onPeerID({(peerID: MCPeerID) in
            dispatch_async(dispatch_get_main_queue(), {
                self.peerIDLabel.text = "PeerID: \(peerID.displayName)"
            })
        })
        peer.onPerson({(person: Person) in
            if let interaction = person.interactions.lastObject as? Interaction {
                let otherPerson = interaction.person
                dispatch_async(dispatch_get_main_queue(), {
                    self.textLogView.text = "Previously interacted with \(otherPerson.name) (\(otherPerson.phone)) at \(interaction.date)"
                })
            }
        })
        discoverer.onPeer({(otherPeer: Peer) in
            self.peer.recordInteraction(otherPeer, callback: {(interaction: Interaction) in
                println(interaction)
            })
            otherPeer.onData({(data: Dictionary<String, AnyObject>) in
                dispatch_async(dispatch_get_main_queue(), {
                     self.textLogView.text = data.description
                })
            })
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func buttonDidTouchUpInside(sender: UIButton) {
        if sender == advertisingButton {
            if broadcaster.isBroadcasting {
                broadcaster.kill()
                sender.setTitle("Start Advertising", forState: UIControlState.Normal)
            } else {
                broadcaster.broadcast()
                sender.setTitle("Stop Advertising", forState: UIControlState.Normal)
            }
        } else {
            if discoverer.isDiscovering {
                discoverer.kill()
                sender.setTitle("Start Discovering", forState: UIControlState.Normal)
            } else {
                discoverer.discover()
                sender.setTitle("Stop Discovering", forState: UIControlState.Normal)
            }
        }
    }
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        broadcaster.kill()
        advertisingButton.setTitle("Start Advertising", forState: UIControlState.Normal)
        discoverer.kill()
        discoveringButton.setTitle("Start Discovering", forState: UIControlState.Normal)
        println("killtest")
    }

}

