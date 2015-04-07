//
//  SetupViewController.swift
//  FishBowl
//
//  Created by Larry Zhang on 4/7/15.
//  Copyright (c) 2015 com.fishbowl. All rights reserved.
//

import UIKit

class SetupViewController: UIViewController {

    @IBOutlet weak var phone: UITextField!
    @IBOutlet weak var twitter: UITextField!
    @IBOutlet weak var snapchat: UITextField!
    @IBAction func skip(sender: AnyObject) {
        settings.doneSetup()
    }
    
    let settings = Settings()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setup() {
        
    }
    
//    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
//        view.endEditing(true)
//        super.touchesBegan(touches, withEvent: event)
//    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
