//
//  ViewController.swift
//  PersonLog
//
//  Created by Yasyf Mohamedali on 2015-03-17.
//  Copyright (c) 2015 Yasyf Mohamedali. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var advertisingButton: UIButton!
    @IBOutlet weak var discoveringButton: UIButton!
    
    let serviceType = "personlog-disc"
    let peerID = Peer.defaultPeerID()
    let broadcaster: Broadcaster
    let discoverer: Discoverer
    
    override init() {
        broadcaster = Broadcaster(peerID: peerID, serviceType: serviceType)
        discoverer = Discoverer(peerID: peerID, serviceType: serviceType)
        super.init()
    }

    required init(coder aDecoder: NSCoder) {
        broadcaster = Broadcaster(peerID: peerID, serviceType: serviceType)
        discoverer = Discoverer(peerID: peerID, serviceType: serviceType)
        super.init(coder: aDecoder)
    }
 
   
   override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
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
                discoverer.process()
                sender.setTitle("Start Discovering", forState: UIControlState.Normal)
            } else {
                discoverer.discover()
                sender.setTitle("Stop Discovering", forState: UIControlState.Normal)
            }
        }
    }

}

