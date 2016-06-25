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
    
    @IBOutlet weak var newPasswordField: MaterialTextField!
    @IBOutlet weak var emailField: MaterialTextField!
    @IBOutlet weak var oldPasswordField: MaterialTextField!
    
    let placeholderEmail = NSAttributedString(string: "Email Address", attributes: [NSForegroundColorAttributeName:UIColor.lightTextColor()])
    let placeholderCurrentPassword = NSAttributedString(string: "Current Password", attributes: [NSForegroundColorAttributeName:UIColor.lightTextColor()])
    let placeholderNewPassword = NSAttributedString(string: "New Password", attributes: [NSForegroundColorAttributeName:UIColor.lightTextColor()])
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "SETTINGS"
        print("Loaded")
        
        let tap : UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SettingsVC.dismisskeyboard))
        view.addGestureRecognizer(tap)
        
        setupPlaceholders()
        

    }
    
    func setupPlaceholders() {
        emailField.text = ""
        oldPasswordField.text = ""
        newPasswordField.text = ""
        
        emailField.attributedPlaceholder = placeholderEmail
        oldPasswordField.attributedPlaceholder = placeholderCurrentPassword
        newPasswordField.attributedPlaceholder = placeholderNewPassword
    }
    
    func dismisskeyboard() {
        self.view.endEditing(true)
    }
    
    @IBAction func changePasswordBtnTapped(sender: AnyObject) {
        if newPasswordField.text?.characters.count < 6 {
            JSSAlertView().danger(self, title: "Invalid Password", text: "The password must have atleast 6 characters.")
            return
        }
        
        if newPasswordField.text == oldPasswordField.text {
            JSSAlertView().danger(self, title: "Invalid Password", text: "Your new password can't be the same as your current.")
            return
        }
        
        dismisskeyboard()
        
        DataService.ds.REF_USER_CURRENT.changePasswordForUser(emailField.text, fromOld: oldPasswordField.text,
                                                              toNew: newPasswordField.text, withCompletionBlock: { error in
                                                                
                                                                if error != nil {
                                                                    print(error.debugDescription)
                                                                    JSSAlertView().danger(self, title: "Invalid Credentials", text: "There is no such user, please try again.")
                                                                } else {
                                                                    print("Password changed!")
                                                                    self.setupPlaceholders()
                                                                    self.successAlertNew("Password Changed", msg: "You have successfully changed your password.")
                                                                }
        })
        
    }
    
    func successAlertNew(title: String, msg: String) {
        let alertview = JSSAlertView().show(self, title: title, text: msg, buttonText: "Ok", color: UIColorFromHex(0x25c151, alpha: 1))
        alertview.setTextTheme(.Light)
        alertview.setTitleFont("Avenir-Heavy")
        alertview.setTextFont("Avenir-Light")
        alertview.setButtonFont("Avenir-Heavy")
    }
    
    func answeredYes() {
        print("Yes")
    }
    
    func answeredNo() {
        print("No")
    }
    
    @IBAction func logoutBtnTapped(sender: AnyObject) {
        
        let alertview = JSSAlertView().show(self, title: "Are You Sure?", text: "You will now be logged out.", buttonText: "Yes", cancelButtonText: "No", color: UIColorFromHex(0xe64c3c, alpha: 1))
        alertview.setTextTheme(.Light)
        alertview.addAction(answeredYes)
        alertview.addCancelAction(answeredNo)
        print("Log Out")
        
        //        DataService.ds.REF_BASE.unauth()
    }
}
