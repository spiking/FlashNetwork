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

class ViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        alertViewSetup()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // If already signed up, login
        if NSUserDefaults.standardUserDefaults().valueForKey(KEY_UID) != nil {
            self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
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
    
    
    @IBAction func fbBtnPressed(sender: UIButton!) {
        
        if !isConnectedToNetwork() {
            JSSAlertView().danger(self, title: "No Internet Connection", text: "To sign up or login, please connect to a network.")
            return
        }
        
        let facebookLogin = FBSDKLoginManager()
        
        facebookLogin.logInWithReadPermissions(["email"]) { (facebookResult: FBSDKLoginManagerLoginResult!, facebookError: NSError!) -> Void in
            
            if facebookError != nil {
                print("Facebook login failed. Error \(facebookError)")
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
                        // Check if id already exist in firebase, if so -> dont re-create
                        DataService.ds.REF_USERS.observeEventType(.Value, withBlock: { snapshot in
                          
                            print("Check user!")
                            
                            if snapshot.hasChild(authData.uid) {
                                print("User already exists, login!")
                                NSUserDefaults.standardUserDefaults().setValue(authData.uid, forKey: KEY_UID)
                                let old = "OldAccount"
                                self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: old)
                            } else {
                                print("User does not exist, create a new!")
                                let user = ["provider": authData.provider!]
                                DataService.ds.createFirebaseUser(authData.uid, user: user)
                                NSUserDefaults.standardUserDefaults().setValue(authData.uid, forKey: KEY_UID)
                                let new = "NewAccount"
                                self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: new)
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
                        print("Error code FIREBASE_AUTH")
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
                                print("Save locally!")
                                // Authorize account
                                DataService.ds.REF_BASE.authUser(email, password: pwd, withCompletionBlock: { err, authData in
                                    
                                    if err != nil {
                                        JSSAlertView().danger(self, title: "Could not authorize account", text: "Please try again or come back later.")
                                    } else {
                                        // Create firebase user
                                        let user = ["provider": authData.provider!, "timestamp": Timestamp]
                                        DataService.ds.createFirebaseUser(authData.uid, user: user)
                                        let new = "NEW_ACCOUNT"
                                        self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: new)
                                    }
                                })
                            }
                        })
                    } else {
                        JSSAlertView().danger(self, title: "Incorrect Credentials", text: "Please check your email and password.")
                    }
                } else {
                    
                    EZLoadingActivity.show("Logging in...", disableUI: false)
                    
                    // If app has been reinstalled, add NSUser data to account
                    
                    if NSUserDefaults.standardUserDefaults().valueForKey("username") != nil {
                        self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
                    } else {
                         NSUserDefaults.standardUserDefaults().setValue(authData.uid, forKey: KEY_UID)
                         let old = "OLD_ACCOUNT"
                         self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: old)
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
        }
    }
    
    func dismisskeyboard() {
        view.endEditing(true)
    }
    
    @IBAction func forgotButtonTapped(sender: AnyObject) {
        print("Load screen")
    }
}

