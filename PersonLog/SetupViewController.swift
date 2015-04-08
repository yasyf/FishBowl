//
//  SetupViewController.swift
//  FishBowl
//
//  Created by Larry Zhang on 4/7/15.
//  Copyright (c) 2015 com.fishbowl. All rights reserved.
//

import UIKit

class SetupViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var phone: UITextField!
    @IBOutlet weak var twitter: UITextField!
    @IBOutlet weak var snapchat: UITextField!
    @IBOutlet weak var skipButton: UIButton!
    @IBAction func skip(sender: AnyObject) {
        settings.doneSetup()
    }
    
    let settings = Settings()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        phone.delegate = self
        twitter.delegate = self
        snapchat.delegate = self

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        skipButton.setTitle("Done", forState: .Normal)
        switch textField {
        case phone:
            settings.setPhone(phone.text)
        case twitter:
            settings.setTwitter(twitter.text)
        case snapchat:
            settings.setSnapchat(snapchat.text)
        default: ()
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == snapchat {
            settings.doneSetup()
            textField.resignFirstResponder()
            self.performSegueWithIdentifier("completed", sender: nil)
            return true
        }
        return false
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
