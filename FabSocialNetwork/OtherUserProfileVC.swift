//
//  OtherUserProfileVC.swift
//  FabSocialNetwork
//
//  Created by Adam Thuvesen on 2016-07-09.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import UIKit
import Firebase
import Alamofire
import JSSAlertView
import Async

class OtherUserProfileVC: UIViewController {
    
    var otherUserKey: String!
    var profileUrl: String!
    private var _request: Request?
    
    var request: Request? {
        return _request
    }
    
    @IBOutlet weak var usernameLbl: UILabel!
    @IBOutlet weak var scoreLbl: UILabel!
    @IBOutlet weak var profileImg: UIImageView!
    @IBOutlet weak var profileImgButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        profileImg.layer.cornerRadius = profileImg.frame.width / 2
        profileImg.clipsToBounds = true
        
        title = "PROFILE"
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Plain, target:nil, action:nil)
        
        navigationItem.leftItemsSupplementBackButton = true
        
        let blockButton = seutpBlockButton()
        let chatButton = setupChatButton()
        let fixed: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FixedSpace, target: nil, action: nil)
        fixed.width = 12
        navigationItem.setRightBarButtonItems([blockButton, fixed, chatButton], animated: true)
      
        NSNotificationCenter.defaultCenter().postNotificationName("load", object: nil)
        
        loadUserFromFirebase()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if UIApplication.sharedApplication().isIgnoringInteractionEvents() {
            UIApplication.sharedApplication().endIgnoringInteractionEvents()
        }
    }
    
    func seutpBlockButton() -> UIBarButtonItem {
        let button: UIButton = UIButton(type: UIButtonType.Custom)
        button.setImage(UIImage(named: "Report.png"), forState: UIControlState.Normal)
        button.addTarget(self, action: #selector(OtherUserProfileVC.blockUserAlert), forControlEvents: UIControlEvents.TouchUpInside)
        button.frame = CGRectMake(0, 0, 25, 25)
        let barButton = UIBarButtonItem(customView: button)
        return barButton
    }
    
    func setupChatButton() -> UIBarButtonItem {
        let button: UIButton = UIButton(type: UIButtonType.Custom)
        button.setImage(UIImage(named: "Chat.png"), forState: UIControlState.Normal)
        button.addTarget(self, action: #selector(OtherUserProfileVC.startChat), forControlEvents: UIControlEvents.TouchUpInside)
        button.frame = CGRectMake(0, 0, 25, 25)
        let barButton = UIBarButtonItem(customView: button)
        return barButton
    }
    
    func blockUserAlert() {
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()
        let alertview = JSSAlertView().show(self, title: "Block User", text: "Do you want to block \(usernameLbl.text!)? You will not be able to see any acitivty from this user, and vice versa. This cannot be undone. \n", buttonText: "Yes", cancelButtonText: "No", color: UIColorFromHex(0xe64c3c, alpha: 1))
        alertview.setTextTheme(.Light)
        alertview.addAction(blockUserAnswerYes)
        alertview.addCancelAction(blockUserAnswerNo)
        
        Async.background(after: 0.5) {
            if UIApplication.sharedApplication().isIgnoringInteractionEvents() {
                UIApplication.sharedApplication().endIgnoringInteractionEvents()
            }
        }
    }
    
    func blockUserAnswerYes() {
        blockUser()
    }
    
    func blockUserAnswerNo() {
        // Do nothing
    }
    
    func blockUser() {
        DataService.ds.REF_USER_CURRENT.child("blocked_users").child(otherUserKey).setValue("TRUE")
        DataService.ds.REF_USERS.child(otherUserKey).child("blocked_users").child(currentUserKey()).setValue("TRUE")
        NSNotificationCenter.defaultCenter().postNotificationName("update", object: nil)
    }
    
    func startChat() {
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()
        self.performSegueWithIdentifier(SEGUE_CHATVC, sender: otherUserKey)
        
        Async.background(after: 0.5) {
            if UIApplication.sharedApplication().isIgnoringInteractionEvents() {
                UIApplication.sharedApplication().endIgnoringInteractionEvents()
            }
        }
    }
    
    func loadProfileImageFromDatabase(profileUrl: String) {
        _request = Alamofire.request(.GET, profileUrl).validate(contentType: ["image/*"]).response(completionHandler: { (request, response, data, err) in
            if err == nil {
                let img = UIImage(data: data!)!
                self.profileImg.image = img
                self.profileImgButton.imageView?.image = UIImage(named: "ImageSelected")
                FeedVC.imageCache.setObject(img, forKey: profileUrl)
            }
        })
    }
    
    func loadUserFromFirebase() {
        
        DataService.ds.REF_USERS.child(otherUserKey).observeSingleEventOfType(.Value, withBlock: { snapshot in
            
            var profileImageSelected = false
            
            if (snapshot.value as? NSNull) == nil {
                if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                    for snap in snapshot {
                        if snap.key == "imgUrl" {
                            self.profileUrl = snap.value as! String
                            if let profileImg = FeedVC.imageCache.objectForKey(self.profileUrl!) as? UIImage {
                                self.profileImg.image = profileImg
                                self.profileImgButton.imageView?.image = UIImage(named: "ImageSelected")
                            } else {
                                self.loadProfileImageFromDatabase(self.profileUrl)
                            }
                            profileImageSelected = true
                        } else if snap.key == "username" {
                            let username = snap.value as! String
                            self.usernameLbl.text = username.capitalizedString
                        } else if snap.key == "score" {
                            let score = snap.value as! Int
                            self.scoreLbl.text = "\(score)"
                        }
                    }
                }
            }
            
            if !profileImageSelected {
                self.profileImg.image = UIImage(named: "NoProfileImageBig.png")
            }
        })
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        switch segue.identifier {
            
        case SEGUE_SHOWUSERPOSTVC?:
            if let userPostVC = segue.destinationViewController as? UserPostsVC {
                if let otherUserKey = sender as? String {
                    userPostVC.userKey = otherUserKey
                }
            }
        case SEGUE_CHATVC?:
            if let chatVC = segue.destinationViewController as? ChatVC {
                if let otherUserKey = sender as? String {
                    chatVC.otherUserKey = otherUserKey
                    chatVC.senderId = currentUserKey()
                    chatVC.otherUsername = usernameLbl.text!
                    chatVC.senderDisplayName = ""
                    
                }
            }
        default:
            break
        }
    }
    
    @IBAction func postsBtnTapped(sender: AnyObject) {
        self.performSegueWithIdentifier(SEGUE_SHOWUSERPOSTVC, sender: otherUserKey)
    }
}
