//
//  SettingsVC.swift
//  FabSocialNetwork
//
//  Created by Adam Thuvesen on 2016-06-24.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import UIKit
import JSSAlertView
import Firebase
import EZLoadingActivity

class SettingsVC: UIViewController, UITextFieldDelegate {
    
    private let placeholderEmail = NSAttributedString(string: "Email Address", attributes: [NSForegroundColorAttributeName:UIColor.lightTextColor()])
    private let placeholderCurrentPassword = NSAttributedString(string: "Current Password", attributes: [NSForegroundColorAttributeName:UIColor.lightTextColor()])
    private let placeholderNewPassword = NSAttributedString(string: "New Password", attributes: [NSForegroundColorAttributeName:UIColor.lightTextColor()])
    private var keyboardVisible = false
    
    @IBOutlet weak var newPasswordField: DarkTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap : UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SettingsVC.dismisskeyboard))
        view.addGestureRecognizer(tap)
        
        title = "SETTINGS"
        
        setupPlaceholders()
        
        if iphoneType == "4" || iphoneType == "5" {
            
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CommentsVC.keyboardWillShow(_:)), name:UIKeyboardWillShowNotification, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CommentsVC.keyboardWillHide(_:)), name:UIKeyboardWillHideNotification, object: nil)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if UIApplication.sharedApplication().isIgnoringInteractionEvents() {
            UIApplication.sharedApplication().endIgnoringInteractionEvents()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.dismisskeyboard()
    }
    
    func setupPlaceholders() {
        newPasswordField.text = ""
        newPasswordField.attributedPlaceholder = placeholderNewPassword
    }
    
    func dismisskeyboard() {
        self.view.endEditing(true)
    }
    
    func keyboardWillShow(sender: NSNotification) {
        
        if keyboardVisible {
            return
        }
        
        UIView.animateWithDuration(0.1, animations: { () -> Void in
            self.view.frame.origin.y -= 0.26 * 253
            self.keyboardVisible = true
        })
    }
    
    func keyboardWillHide(sender: NSNotification) {
        
        if !keyboardVisible {
            return
        }
        
        UIView.animateWithDuration(0.1, animations: { () -> Void in
            self.view.frame.origin.y += 0.26 * 253
            self.keyboardVisible = false
        })
    }
    
    func answeredYes() {
        
        // Reset NSUserData
        let appDomain = NSBundle.mainBundle().bundleIdentifier!
        NSUserDefaults.standardUserDefaults().removePersistentDomainForName(appDomain)
        
        EZLoadingActivity.hide()
        
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
        
        dismisskeyboard()
        
        if newPasswordField.text?.characters.count < 6 {
            JSSAlertView().danger(self, title: "Could Not Update", text: "The password must have atleast 6 characters.")
            return
        }
        
        FIRAuth.auth()?.currentUser?.updatePassword(newPasswordField.text!, completion: { (error) in
            if error != nil  {
                if error!.code == STATUS_SENSITIVE_DATA_CHANGE {
                    JSSAlertView().danger(self, title: "Could Not Update", text: "Updating a user’s password is a security sensitive operation that requires a recent login from the user. Login again to update your password.")
                } else if error!.code == STATUS_WEAK_PASSWORD {
                    JSSAlertView().danger(self, title: "Could Not Update", text: "The entered password it too weak. Please use a password with atlesat 6 characters.")
                }
            } else {
                successAlertSettingsVC(self, title: "Password Updated", msg: "You have successfully changed your password.")
            }
            self.setupPlaceholders()
        })
    }
}
