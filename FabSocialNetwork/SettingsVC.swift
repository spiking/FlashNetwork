//
//  SettingsVC.swift
//  FabSocialNetwork
//
//  Created by Adam Thuvesen on 2016-06-24.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import UIKit
import JSSAlertView

class SettingsVC: UIViewController {
    
    let placeholderEmail = NSAttributedString(string: "Email Address", attributes: [NSForegroundColorAttributeName:UIColor.lightTextColor()])
    let placeholderCurrentPassword = NSAttributedString(string: "Current Password", attributes: [NSForegroundColorAttributeName:UIColor.lightTextColor()])
    let placeholderNewPassword = NSAttributedString(string: "New Password", attributes: [NSForegroundColorAttributeName:UIColor.lightTextColor()])
    
    @IBOutlet weak var emailField: DarkTextField!
    @IBOutlet weak var currentPasswordField: DarkTextField!
    @IBOutlet weak var newPasswordField: DarkTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap : UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SettingsVC.dismisskeyboard))
        view.addGestureRecognizer(tap)
        
        title = "SETTINGS"
        
        setupPlaceholders()

        isUserAuthenticated(self) 
    }
    
    func setupPlaceholders() {
        emailField.text = ""
        currentPasswordField.text = ""
        newPasswordField.text = ""
        
        emailField.attributedPlaceholder = placeholderEmail
        currentPasswordField.attributedPlaceholder = placeholderCurrentPassword
        newPasswordField.attributedPlaceholder = placeholderNewPassword
    }
    
    func dismisskeyboard() {
        self.view.endEditing(true)
    }
    
    func answeredYes() {
        // Reset NSUserData
        let appDomain = NSBundle.mainBundle().bundleIdentifier!
        NSUserDefaults.standardUserDefaults().removePersistentDomainForName(appDomain)
        
        // Push to login view
        let loginVC: UIViewController? = self.storyboard?.instantiateViewControllerWithIdentifier("InitalNavigationController")
        self.presentViewController(loginVC!, animated: true, completion: nil)
    }
    
    func answeredNo() {
        // Do nothing
    }
    
    @IBAction func logoutBtnTapped(sender: AnyObject) {
        
        let alertview = JSSAlertView().show(self, title: "Logout", text: "Do you want to logout?", buttonText: "Yes", cancelButtonText: "No", color: UIColorFromHex(0xe64c3c, alpha: 1))
        alertview.setTextTheme(.Light)
        alertview.addAction(answeredYes)
        alertview.addCancelAction(answeredNo)
        
    }
    
    @IBAction func changePasswordBtnTapped(sender: AnyObject) {
        if newPasswordField.text?.characters.count < 6 {
            JSSAlertView().danger(self, title: "Invalid Password", text: "The password must have atleast 6 characters.")
            return
        }
        
        if newPasswordField.text == currentPasswordField.text {
            JSSAlertView().danger(self, title: "Invalid Password", text: "Your new password cannot be the same as your current.")
            return
        }
        
        dismisskeyboard()
        
        DataService.ds.REF_USER_CURRENT.changePasswordForUser(emailField.text, fromOld: currentPasswordField.text,
                                                              toNew: newPasswordField.text, withCompletionBlock: { error in
                                                                
                                                                if error != nil {
                                                                    JSSAlertView().danger(self, title: "Invalid Credentials", text: "There is no such user, please try again.")
                                                                } else {
                                                                    self.setupPlaceholders()
                                                                    successAlertSettingsVC(self, title: "Password Changed", msg: "You have successfully changed your password.")
                                                                }
        })
        
    }
}
