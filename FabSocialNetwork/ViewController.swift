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

class ViewController: UIViewController {
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // If already signed up, login
        if NSUserDefaults.standardUserDefaults().valueForKey(KEY_UID) != nil {
            self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
        }
        
        let tap : UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismisskeyboard")
        view.addGestureRecognizer(tap)
    }
    
    @IBAction func fbBtnPressed(sender: UIButton!) {
        let facebookLogin = FBSDKLoginManager()
        
        facebookLogin.logInWithReadPermissions(["email"]) { (facebookResult: FBSDKLoginManagerLoginResult!, facebookError: NSError!) -> Void in
            
            if facebookError != nil {
                print("Facebook login failed. Error \(facebookError)")
            } else {
                let accessToken = FBSDKAccessToken.currentAccessToken().tokenString
                print("Successfully logged in with facebook. \(accessToken)")
                
                // Authenticate facebook login with firebase
                DataService.ds.REF_BASE.authWithOAuthProvider("facebook", token: accessToken, withCompletionBlock: { error, authData  in
                    
                    if error != nil {
                        print("Login failed! \(error)")
                    } else {
                        print("Logged In! \(authData)")
                        
                        // Create Firebase user
                        let user = ["provider": authData.provider!]
                        DataService.ds.createFirebaseUser(authData.uid, user: user)
                        
                        NSUserDefaults.standardUserDefaults().setValue(authData.uid, forKey: KEY_UID)
                        self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
                    }
                    
                })
                
            }
            
        }
    }
    
    @IBAction func attemptLogin(sender: UIButton!) {
        if let email = emailField.text where email != "", let pwd = passwordField.text where pwd != "" {
            
            DataService.ds.REF_BASE.authUser(email, password: pwd, withCompletionBlock: { (error, authData) in
                
                if error != nil {
                    print(error)
                    print("User does not exist!")
                    // User does not exist, try to create an account
                    
                    // Should not be zero, error codes not working properly atm
                    if error.code != 0 {
                        
                        DataService.ds.REF_BASE.createUser(email, password: pwd, withValueCompletionBlock: { (error, result) in
                            
                            // Try to creat account
                            if error != nil {
                                errorAlert("Could not create account!", subTitle: "Problem occured when creating an account. Please try again or come back later.")
                            } else {
                                // Save account locally
                                NSUserDefaults.standardUserDefaults().setValue(result[KEY_UID], forKey: KEY_UID)
                                print("Save locally!")
                                // Authorize account
                                DataService.ds.REF_BASE.authUser(email, password: pwd, withCompletionBlock: { err, authData in
                                    
                                    if err != nil {
                                        errorAlert("Could not authorize account!", subTitle: "Please try again.")
                                    } else {
                                        // Create firebase user
                                        let user = ["provider": authData.provider!]
                                        DataService.ds.createFirebaseUser(authData.uid, user: user)
                                        self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
                                        
                                    //  self.showAlert("New account created!", msg: "A new account has succesfully been created.")
                                    }
                                })
                            }
                        })
                    } else {
                        errorAlert("Incorrect credentials", subTitle: "Please check your email and password.")
                    }
                } else {
                    self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
                }
            })
            
        } else {
            errorAlert("Invalid input", subTitle: "You must enter an email and a password.")
        }
    }
    
    func dismisskeyboard() {
        view.endEditing(true)
    }
    
}

