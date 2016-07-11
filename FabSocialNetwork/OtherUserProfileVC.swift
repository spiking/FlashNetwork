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

class OtherUserProfileVC: UIViewController {

    var otherUserKey: String!
    var request: Request?
    
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
        
        seutpBlockButton()
        
        loadUserFromFirebase()
    }
    
    func seutpBlockButton() {
        let button: UIButton = UIButton(type: UIButtonType.Custom)
        button.setImage(UIImage(named: "Report.png"), forState: UIControlState.Normal)
        button.addTarget(self, action: #selector(OtherUserProfileVC.blockUserAlert), forControlEvents: UIControlEvents.TouchUpInside)
        button.frame = CGRectMake(0, 0, 25, 25)
        let barButton = UIBarButtonItem(customView: button)
        self.navigationItem.rightBarButtonItem = barButton
    }
    
    func blockUserAlert() {
        let alertview = JSSAlertView().show(self, title: "Block User", text: "Do you want to block \(usernameLbl.text!)? You will not be able to see any acitivty from this user, and vice versa. This cannot be undone. \n", buttonText: "Yes", cancelButtonText: "No", color: UIColorFromHex(0xe64c3c, alpha: 1))
        alertview.setTextTheme(.Light)
        alertview.addAction(blockUserAnswerYes)
        alertview.addCancelAction(blockUserAnswerNo)
    }
    
    func blockUserAnswerYes() {
        blockUser()
    }
    
    func blockUserAnswerNo() {
        // Do nothing
    }
    
    func blockUser() {
        DataService.ds.REF_USER_CURRENT.childByAppendingPath("blocked_users").childByAppendingPath(otherUserKey).setValue("TRUE")
        DataService.ds.REF_USERS.childByAppendingPath(otherUserKey).childByAppendingPath("blocked_users").childByAppendingPath(currentUserKey()).setValue("TRUE")
        
        NSNotificationCenter.defaultCenter().postNotificationName("update", object: nil)
    }
    
    func loadProfileImageFromDatabase(profileUrl: String) {
        request = Alamofire.request(.GET, profileUrl).validate(contentType: ["image/*"]).response(completionHandler: { (request, response, data, err) in
            if err == nil {
                let img = UIImage(data: data!)!
                self.profileImg.image = img
                self.profileImgButton.imageView?.image = UIImage(named: "ImageSelected")
                FeedVC.imageCache.setObject(img, forKey: profileUrl)
            }
        })
    }
    
    func loadUserFromFirebase() {
        
        DataService.ds.REF_USERS.childByAppendingPath(otherUserKey).observeSingleEventOfType(.Value, withBlock: { snapshot in
            
            if (snapshot.value as? NSNull) != nil {
            
            } else {

                if let snapshot = snapshot.children.allObjects as? [FDataSnapshot] {
                    for snap in snapshot {
                        
                        if snap.key == "imgUrl" {
                            let profileUrl = snap.value as! String
                            
                            if let profileImg = FeedVC.imageCache.objectForKey(profileUrl) as? UIImage {
                                self.profileImg.image = profileImg
                                self.profileImgButton.imageView?.image = UIImage(named: "ImageSelected")
                            } else {
                                self.loadProfileImageFromDatabase(profileUrl)
                            }
                            
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
            
        })
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == SEGUE_SHOWUSERPOSTVC {
            if let userPostVC = segue.destinationViewController as? UserPostsVC {
                if let otherUserKey = sender as? String {
                    userPostVC.userKey = otherUserKey
                }
            }
        }
    }
    
    @IBAction func postsBtnTapped(sender: AnyObject) {
        self.performSegueWithIdentifier(SEGUE_SHOWUSERPOSTVC, sender: otherUserKey)
    }
}