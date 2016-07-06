//
//  UserAgreementVC.swift
//  FabSocialNetwork
//
//  Created by Adam Thuvesen on 2016-07-04.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import UIKit
import EZLoadingActivity
import Firebase

class UserAgreementVC: UIViewController, UIScrollViewDelegate {

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var acceptBtn: UIButton!
    
    var typeOfLogin = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        EZLoadingActivity.hide()
        navigationItem.setHidesBackButton(true, animated: true)
        NSUserDefaults.standardUserDefaults().setValue("FALSE", forKey: "terms")
        title = "USER AGREEMENT"
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        textView.setContentOffset(CGPointZero, animated: false)
    }
    
    @IBAction func acceptBtnTapped(sender: AnyObject) {
        
        userAcceptedTerms()
        
        if typeOfLogin == "OLD_ACCOUNT" {
             self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: typeOfLogin)
        } else {
            self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: typeOfLogin)
        }
    }
    
    
    func userAcceptedTerms() {
        DataService.ds.REF_USER_CURRENT.childByAppendingPath("terms").setValue("TRUE")
        NSUserDefaults.standardUserDefaults().setValue("TRUE", forKey: "terms")
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if let nav = segue.destinationViewController as? UINavigationController {
            if segue.identifier == SEGUE_LOGGED_IN {
                if let feedVC = nav.topViewController as? FeedVC {
                    if let typeOfLogin = sender as? String {
                        feedVC.typeOfLogin = typeOfLogin
                    }
                }
            }
        }
    }
}
