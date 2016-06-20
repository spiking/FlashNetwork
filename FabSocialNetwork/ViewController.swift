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
import SCLAlertView
import Firebase
import EZLoadingActivity

class ViewController: UIViewController {
    
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
    }
    
    @IBAction func fbBtnPressed(sender: UIButton!) {
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
                                self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
                            } else {
                                print("User does not exist, create a new!")
                                let user = ["provider": authData.provider!]
                                DataService.ds.createFirebaseUser(authData.uid, user: user)
                                NSUserDefaults.standardUserDefaults().setValue(authData.uid, forKey: KEY_UID)
                                self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
                            }
                        })
                    }
                    
                })
                
            }
            
        }
    }
    
    @IBAction func attemptLogin(sender: UIButton!) {
        if let email = emailField.text where email != "", let pwd = passwordField.text where pwd != "" {
            
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
                                errorAlert("Could not create account", subTitle: "\nProblem occured when creating an account. Please try again or come back later.")
                            } else {
                                // Save account locally
                                NSUserDefaults.standardUserDefaults().setValue(result[KEY_UID], forKey: KEY_UID)
                                print("Save locally!")
                                // Authorize account
                                DataService.ds.REF_BASE.authUser(email, password: pwd, withCompletionBlock: { err, authData in
                                    
                                    if err != nil {
                                        errorAlert("Could not authorize account", subTitle: "\nPlease try again or come back later.")
                                    } else {
                                        // Create firebase user
                                        let user = ["provider": authData.provider!]
                                        DataService.ds.createFirebaseUser(authData.uid, user: user)
                                        self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
                                    }
                                })
                            }
                        })
                    } else {
                        errorAlert("Incorrect credentials", subTitle: "\nPlease check your email and password.")
                    }
                } else {
                    
                    EZLoadingActivity.show("Logging in...", disableUI: false)
                    
                    // If app has been reinstalled, add NSUser data to account
                    
                    if NSUserDefaults.standardUserDefaults().valueForKey("username") != nil {
                        self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
                    } else {
                         print("Need to add NSUser data since app has been uninstalled")
                         NSUserDefaults.standardUserDefaults().setValue(authData.uid, forKey: KEY_UID)
                         self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
                    }
                }
            })
            
        } else {
            errorAlert("Invalid input", subTitle: "\nYou must enter an email and a password.")
        }
    }
    
    func dismisskeyboard() {
        view.endEditing(true)
    }

}

