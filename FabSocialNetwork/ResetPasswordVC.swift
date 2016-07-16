//
//  ResetPasswordVC.swift
//  FabSocialNetwork
//
//  Created by Adam Thuvesen on 2016-06-23.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import UIKit
import JSSAlertView
import Firebase

class ResetPasswordVC: UIViewController {
    
    @IBOutlet weak var emailField: DarkTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap : UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.dismisskeyboard))
        view.addGestureRecognizer(tap)
        
        setupPlaceholders()
    }
    
    func setupPlaceholders() {
        let placeholderEmail = NSAttributedString(string: "Email Address", attributes: [NSForegroundColorAttributeName:UIColor.lightTextColor()])
        emailField.attributedPlaceholder = placeholderEmail
    }
    
    func dismisskeyboard() {
        view.endEditing(true)
    }
    
    @IBAction func resetPassword() {
        
        if !isConnectedToNetwork() {
            JSSAlertView().danger(self, title: "No Internet Connection", text: "Please connect to a network and try again.")
        }
        
        dismisskeyboard()
        
        if emailField.text != "" {
            FIRAuth.auth()?.sendPasswordResetWithEmail(emailField.text!, completion: { (error) in
                if error != nil {
                    print(error)
                    JSSAlertView().danger(self, title: "No User Found", text: "There is no user with the entered email address. Please try again.")
                } else {
                    successAlertResetPasswordVC(self, title: "Email Sent", msg: "Reset instruction has been sent to the entered email address.")
                }
                
            })
        }
    }
}
