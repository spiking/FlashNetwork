//
//  ViewController.swift
//  MySocialMedia
//
//  Created by Adam Thuvesen on 2016-06-02.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import Firebase
import JSSAlertView
import EZLoadingActivity
import Async

class ViewController: UIViewController, UITextFieldDelegate {
    
    var userHasAcceptedTerms = false
    let OLD_ACCOUNT = "OLD_ACCOUNT"
    let NEW_ACCOUNT = "NEW_ACCOUNT"
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        alertViewSetup()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if userBanned {
            JSSAlertView().danger(self, title: "Banned", text: "You have violated the user license agreement. Your account has been permanetly banned from Flash Network.")
            NSTimer.scheduledTimerWithTimeInterval(7, target: self, selector: #selector(ViewController.terminateApp), userInfo: nil, repeats: false)
        }
        
        checkiPhoneType()
        
        if NSUserDefaults.standardUserDefaults().valueForKey(KEY_UID) != nil && NSUserDefaults.standardUserDefaults().valueForKey("terms") as? String == "TRUE" {
            firstLogin = false
            self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
        } else {
            firstLogin = true
        }
        
        let tap : UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.dismisskeyboard))
        view.addGestureRecognizer(tap)
        
        setupPlaceholders()
        
        emailField.delegate = self
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Plain, target:nil, action:nil)
        
    }
    
    func setupPlaceholders() {
        let placeholderEmail = NSAttributedString(string: "Email Address", attributes: [NSForegroundColorAttributeName:UIColor.lightTextColor()])
        emailField.attributedPlaceholder = placeholderEmail
        let placeholderPassword = NSAttributedString(string: "Password", attributes: [NSForegroundColorAttributeName:UIColor.lightTextColor()])
        passwordField.attributedPlaceholder = placeholderPassword
        emailField.attributedPlaceholder = placeholderEmail
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == emailField {
            self.passwordField.becomeFirstResponder()
        }
        
        return true
    }
    
    func terminateApp() {
        exit(0)
    }
    
    @IBAction func forgotPasswordBtnPressed(sender: AnyObject) {
        self.performSegueWithIdentifier(SEGUE_RESETPASSWORDVC, sender: nil)
    }
    
    @IBAction func fbBtnPressed(sender: UIButton!) {
        
        if !isConnectedToNetwork() {
            JSSAlertView().danger(self, title: "No Internet Connection", text: "To sign up or login, please connect to a network.")
            return
        }
        
        let facebookLogin = FBSDKLoginManager()
        
        facebookLogin.logInWithReadPermissions(["email"]) { (facebookResult: FBSDKLoginManagerLoginResult!, facebookError: NSError!) -> Void in
            
            if facebookError != nil {
                print("Facebook login failed. Error \(facebookError)")
                JSSAlertView().danger(self, title: "Facebook Login Failed", text: "An unexpected error occured. Please try again.")
            } else if facebookResult.isCancelled {
                print("Facebook login was cancelled.")
            } else {
                let accessToken = FBSDKAccessToken.currentAccessToken().tokenString
                print("Successfully logged in with facebook. \(accessToken)")
                
                // Authenticate facebook login with firebase
                DataService.ds.REF_BASE.authWithOAuthProvider("facebook", token: accessToken, withCompletionBlock: { error, authData  in
                    
                    if error != nil {
                        print("Login failed! \(error)")
                    } else {
                        print("Logged In! \(authData)")
                        
                        // Check if id already exist in firebase, if so, dont recreate
                        DataService.ds.REF_USERS.observeSingleEventOfType(.Value, withBlock: { snapshot in
                            
                            if !snapshot.hasChild(authData.uid) {
                                
                                EZLoadingActivity.show("Creating account...", disableUI: false)
                                
                                let user = ["provider": authData.provider!, "timestamp": Timestamp, "score" : 0]
                                DataService.ds.createFirebaseUser(authData.uid, user: user as! Dictionary<String, AnyObject>)
                                NSUserDefaults.standardUserDefaults().setValue(authData.uid, forKey: KEY_UID)
                                self.performSegueWithIdentifier(SEGUE_USERAGREEMENTVC, sender: self.NEW_ACCOUNT)
                                
                            } else {
                                
                                EZLoadingActivity.show("Logging in...", disableUI: false)
                                
                                if !userProfileAdded() {
                                    NSUserDefaults.standardUserDefaults().setValue(authData.uid, forKey: KEY_UID)
                                }
                                
                                var accepted = false
                                
                                // Perform user term check on background thread
                                
                                Async.background() {
                                    
                                    DataService.ds.REF_USER_CURRENT.observeSingleEventOfType(.Value, withBlock: { snapshot in
                                        
                                        if let terms = snapshot.value["terms"] as? String {
                                            if terms == "TRUE" {
                                                accepted = true
                                            }
                                        }
                                    })
                                    
                                    // Must perform segues on main thread
                                    
                                    }.main(after: 1.0) {
                                        if !accepted {
                                            // Means user entered user agreement but terminated the app
                                            if let terms = NSUserDefaults.standardUserDefaults().valueForKey("terms") as? String where terms == "FALSE" {
                                                self.performSegueWithIdentifier(SEGUE_USERAGREEMENTVC, sender: self.NEW_ACCOUNT)
                                            } else {
                                                self.performSegueWithIdentifier(SEGUE_USERAGREEMENTVC, sender: self.OLD_ACCOUNT)
                                            }
                                        } else {
                                            self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: self.OLD_ACCOUNT)
                                        }
                                }
                            }
                        })
                    }
                })
            }
        }
    }
    
    @IBAction func attemptLogin(sender: UIButton!) {
        
        dismisskeyboard()
        
        if let email = emailField.text where email != "", let pwd = passwordField.text where pwd != "" {
            
            if !isConnectedToNetwork() {
                JSSAlertView().danger(self, title: "No Internet Connection", text: "To sign up or login, please connect to a network.")
                return
            }
            
            if passwordField.text?.characters.count < 6 {
                JSSAlertView().danger(self, title: "Invalid Password", text: "The password must have atleast 6 characters.")
                return
            }
            
            DataService.ds.REF_BASE.authUser(email, password: pwd, withCompletionBlock: { (error, authData) in
                
                // Check if account exist
                if error != nil {
                    print(error)
                    
                    if error.code == STATUS_ACCOUNT_FIREBASE_AUTH {
                        print("\(error.debugDescription)")
                    }
                    
                    if error.code == STATUS_ACCOUNT_NONEXIST {
                        // User does not exist, try to create an account
                        DataService.ds.REF_BASE.createUser(email, password: pwd, withValueCompletionBlock: { (error, result) in
                            
                            EZLoadingActivity.show("Creating account...", disableUI: false)
                            
                            // Try to creat account
                            if error != nil {
                                JSSAlertView().danger(self, title: "Could not create account", text: "Problem occured when creating an account. Please try again or come back later.")
                            } else {
                                // Save account locally
                                NSUserDefaults.standardUserDefaults().setValue(result[KEY_UID], forKey: KEY_UID)
                                // Authorize account
                                DataService.ds.REF_BASE.authUser(email, password: pwd, withCompletionBlock: { err, authData in
                                    
                                    if err != nil {
                                        JSSAlertView().danger(self, title: "Could not authorize account", text: "Please try again or come back later.")
                                    } else {
                                        // Create firebase user
                                        let user = ["provider": authData.provider!, "timestamp": Timestamp, "score" : 0]
                                        DataService.ds.createFirebaseUser(authData.uid, user: user as! Dictionary<String, AnyObject>)
                                        self.performSegueWithIdentifier(SEGUE_USERAGREEMENTVC, sender: self.NEW_ACCOUNT)
                                    }
                                })
                            }
                        })
                    } else {
                        JSSAlertView().danger(self, title: "Incorrect Credentials", text: "Please check your email and password.")
                    }
                } else {
                    
                    EZLoadingActivity.show("Logging in...", disableUI: false)
                    
                    if !userProfileAdded() {
                        NSUserDefaults.standardUserDefaults().setValue(authData.uid, forKey: KEY_UID)
                    }
                    
                    var accepted = false
                    
                    // Perform user term check on background thread
                    
                    Async.background() {
                        
                        DataService.ds.REF_USER_CURRENT.observeSingleEventOfType(.Value, withBlock: { snapshot in
                            
                            if let terms = snapshot.value["terms"] as? String {
                                if terms == "TRUE" {
                                    accepted = true
                                }
                            }
                        })
                        
                        // Must perform segues on main thread
                        
                        }.main(after: 1.0) {
                            if !accepted {
                                
                                // Means user entered user agreement but terminated the app
                                if let terms = NSUserDefaults.standardUserDefaults().valueForKey("terms") as? String where terms == "FALSE" {
                                    
                                    self.performSegueWithIdentifier(SEGUE_USERAGREEMENTVC, sender: self.NEW_ACCOUNT)
                                } else {
                                    self.performSegueWithIdentifier(SEGUE_USERAGREEMENTVC, sender: self.OLD_ACCOUNT)
                                }
                                
                            } else {
                                self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: self.OLD_ACCOUNT)
                            }
                    }
                    
                }
            })
            
        } else {
            JSSAlertView().danger(self, title: "Invalid Input", text: "You must enter a valid email and a password.")
        }
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
        } else if segue.identifier == SEGUE_USERAGREEMENTVC {
            if let useragreementVC = segue.destinationViewController as? UserAgreementVC {
                if let typeOfLogin = sender as? String {
                    useragreementVC.typeOfLogin = typeOfLogin
                }
            }
        }
    }
    
    func dismisskeyboard() {
        view.endEditing(true)
    }
}
