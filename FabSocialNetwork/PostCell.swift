//
//  PostCell.swift
//  FabSocialNetwork
//
//  Created by Adam Thuvesen on 2016-06-05.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import UIKit
import Alamofire
import Firebase
import MBProgressHUD
import JSSAlertView
import Async


class PostCell: UITableViewCell {
    
    var commentTapAction: ((UITableViewCell) -> Void)?
    var reportTapAction: ((UITableViewCell) -> Void)?
    var usernameTapAction: ((UITableViewCell) -> Void)?
    
    private var likeRef: FIRDatabaseReference!
    private var userRef: FIRDatabaseReference!
    private var userLikes: FIRDatabaseReference!
    private var userLikedPost = false
    private var _request: Request?
    private var _post: Post?
    
    var post: Post? {
        return _post
    }
    
    var request: Request? {
        return _request
    }
    
    @IBOutlet weak var descLblHeight: NSLayoutConstraint!
    @IBOutlet weak var likesLblWidth: NSLayoutConstraint!
    @IBOutlet weak var profileImg: UIImageView!
    @IBOutlet weak var mainImg: UIImageView!
    @IBOutlet weak var descriptionLbl: UILabel!
    @IBOutlet weak var likesLbl: UILabel!
    @IBOutlet weak var likeImage: UIImageView!
    @IBOutlet weak var usernameLbl: UILabel!
    @IBOutlet weak var timeLbl: UILabel!
    @IBOutlet weak var reportBtn: UIButton!
    @IBOutlet weak var commentBtn: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let tapOnLike = UITapGestureRecognizer(target: self, action: #selector(PostCell.likeTapped(_:)))
        tapOnLike.numberOfTapsRequired = 1
        likeImage.addGestureRecognizer(tapOnLike)
        likeImage.userInteractionEnabled = true
        
        let usernameTapped = UITapGestureRecognizer(target: self, action: #selector(PostCell.usernameTapped(_:)))
        usernameTapped.numberOfTapsRequired = 1
        usernameLbl.addGestureRecognizer(usernameTapped)
        usernameLbl.userInteractionEnabled = true
        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(PostCell.mainImgTapped(_:)))
        doubleTap.numberOfTapsRequired = 2
        mainImg.addGestureRecognizer(doubleTap)
        
    }
    
    override func drawRect(rect: CGRect) {
        profileImg.layer.cornerRadius = profileImg.frame.size.width / 2
        profileImg.clipsToBounds = true
        mainImg.clipsToBounds = true
    }
    
    
    func configureCell(post: Post, img: UIImage?) {
        
        self._post = post
        self.mainImg.image = nil
        self.descriptionLbl.text = post.postDescription
        self.likesLbl.text = "\(post.likes)"
        
        self.timeLbl.text = dateSincePosted(post.timestamp)
        
        self.likesLblWidth.constant = self.likesLbl.intrinsicContentSize().width + 4
        
        self.userRef = DataService.ds.REF_USERS.child(post.userKey)
        self.likeRef = DataService.ds.REF_USER_CURRENT.child("likes").child(post.postKey)
        self.userLikes = DataService.ds.REF_USER_CURRENT.child("likes")
        
        // Main post image
        if post.imageUrl != nil {
            
            let height = heightForView(post.postDescription, width: screenWidth - 48)
            self.descLblHeight.constant = height
            
            if img != nil {
                self.mainImg.image = img
            } else {
                // Not in cache, download and add to cache
                self._request = Alamofire.request(.GET, post.imageUrl!).validate(contentType: ["image/*"]).response(completionHandler: { (request, response, data, err) in
                    if err == nil {
                        let img = UIImage(data: data!)!
                        self.mainImg.image = img
                        FeedVC.imageCache.setObject(img, forKey: self.post!.imageUrl!)
                    }
                })
            }
        } else {
        
            let height = heightForView(post.postDescription, width: screenWidth - 48)
            self.descLblHeight.constant = height
            self.mainImg.hidden = true
        }
        
        // Profile image
        userRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
            
            if let username = snapshot.value!["username"] as? String {
                self.usernameLbl.text = username.capitalizedString
            } else {
                self.usernameLbl.text = "Default Username"
            }
            
            if let profileUrl = snapshot.value!["imgUrl"] as? String {
                
                if let profImage = FeedVC.imageCache.objectForKey(profileUrl) as? UIImage {
                    self.profileImg.image = profImage
                } else {
                    // Not in cache, download and add to cache
                    self._request = Alamofire.request(.GET, profileUrl).validate(contentType: ["image/*"]).response(completionHandler: { (request, response, data, err) in
                        if err == nil {
                            let img = UIImage(data: data!)!
                            self.profileImg.image = img
                            FeedVC.imageCache.setObject(img, forKey: profileUrl)
                        }
                    })
                    
                }
            } else {
                self.profileImg.image = UIImage(named:"NoProfileImage.png")
            }
            
            
            }, withCancelBlock: { error in
                print(error.description)
        })
        
        // If current post exists in current users likes, set heart to full (needed for reinstall)
        
        userLikes.observeSingleEventOfType(.Value, withBlock: { snapshot in
            
            if snapshot.hasChild(post.postKey) {
                self.likeImage.image = UIImage(named: "heart-full")
            }
        })
        
        // Like observer
        
        likeRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
            
            if (snapshot.value as? NSNull) != nil {
                self.userLikedPost = false
                self.likeImage.image = UIImage(named: "heart-empty")
            } else {
                self.userLikedPost = true
                self.likeImage.image = UIImage(named: "heart-full")
            }
        })
    }
    
    func likeTapped(sender: UITapGestureRecognizer) {
        
        if !isConnectedToNetwork() {
            return
        }
        
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()
        
        DataService.ds.REF_POSTS.observeSingleEventOfType(.Value, withBlock: { snapshot in
            
            if snapshot.hasChild(self.post!.postKey) {
                
                self.likeRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
                    
                    // If User haven't like this, then like it, otherwise unlike it
                    
                    if (snapshot.value as? NSNull) != nil {
                        self.userLikedPost = true
                        self.likeRef.setValue(true)
                        self.likeImage.image = UIImage(named: "heart-full")
                        self.post!.adjustLikes(true)
                        self.updateScores(true)
                        self.sendPushNotificationToUser()
                    } else {
                        self.userLikedPost = false
                        self.likeRef.removeValue()
                        self.likeImage.image = UIImage(named: "heart-empty")
                        self.post!.adjustLikes(false)
                        self.updateScores(false)
                    }
                    
                    self.likesLbl.text = "\(self.post!.likes)"
                    
                })
            } else {
                NSNotificationCenter.defaultCenter().postNotificationName("update", object: nil)
            }
        })
        
        Async.background(after: 0.5) {
            if UIApplication.sharedApplication().isIgnoringInteractionEvents() {
                UIApplication.sharedApplication().endIgnoringInteractionEvents()
            }
        }
    }
    
    func sendPushNotificationToUser() {
        DataService.ds.REF_USERS.child(self.post!.userKey).observeSingleEventOfType(.Value) { (snapshot: FIRDataSnapshot!) in
            if let userPushId = snapshot.childSnapshotForPath("userPushId").value as? String {
                if self.post!.userKey != currentUserKey() {
                    let postTime = dateSincePosted(self.post!.timestamp)
                    oneSignal.postNotification(["contents": ["en":"\(getCurrentUsername().capitalizedString) liked your post from \(postTime) ago."], "include_player_ids": [userPushId]])
                }
            }
        }
    }
    
    func updateScores(liked: Bool) {
        
        DataService.ds.REF_USER_CURRENT.child("score").observeSingleEventOfType(.Value, withBlock: { snapshot in
            
            if var score = snapshot.value as? Int {
                
                let diceRoll = Int(arc4random_uniform(2) + 1)
                
                if liked {
                    score += 1 + diceRoll
                } else {
                    score -= 1 + diceRoll
                }
                
                if score < 0 {
                    score = 0
                }
                
                DataService.ds.REF_USER_CURRENT.child("score").setValue(score)
            }
        
        })
        
        DataService.ds.REF_USERS.child(post!.userKey).child("score").observeSingleEventOfType(.Value, withBlock: { snapshot in
            
            if var score = snapshot.value as? Int {
                
                if liked {
                    score += 1
                } else {
                    score -= 1
                }
                
                DataService.ds.REF_USERS.child(self.post!.userKey).child("score").setValue(score)
            }
            
        })

    }
    
    func mainImgTapped(sender: UITapGestureRecognizer) {
        
        if !userLikedPost && isConnectedToNetwork() {
            startLikeAnimation(self.mainImg)
            likeTapped(sender)
        }
    }
    
    func usernameTapped(sender: UITapGestureRecognizer) {
        
        if !isConnectedToNetwork() {
            if UIApplication.sharedApplication().isIgnoringInteractionEvents() {
                UIApplication.sharedApplication().endIgnoringInteractionEvents()
            }
            return
        }
        
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()
        
        if post?.userKey != currentUserKey() && isConnectedToNetwork() {
            self.usernameTapAction?(self)
        }
        
        Async.background(after: 0.5) {
            if UIApplication.sharedApplication().isIgnoringInteractionEvents() {
                UIApplication.sharedApplication().endIgnoringInteractionEvents()
            }
        }
    }
    
    @IBAction func commentsBtnTapped(sender: AnyObject) {
        
        if !isConnectedToNetwork() {
            if UIApplication.sharedApplication().isIgnoringInteractionEvents() {
                if UIApplication.sharedApplication().isIgnoringInteractionEvents() {
                    UIApplication.sharedApplication().endIgnoringInteractionEvents()
                }
            }
            return
        }
        
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()
    
        DataService.ds.REF_POSTS.observeSingleEventOfType(.Value, withBlock: { snapshot in
            
            if snapshot.hasChild(self.post!.postKey) {
                self.commentTapAction?(self)
            } else {
                NSNotificationCenter.defaultCenter().postNotificationName("update", object: nil)
            }
        })
        
        Async.background(after: 0.5) {
            if UIApplication.sharedApplication().isIgnoringInteractionEvents() {
                UIApplication.sharedApplication().endIgnoringInteractionEvents()
            }
        }
    }
    
    @IBAction func reportBtnTapped(sender: AnyObject) {
        
        if !isConnectedToNetwork() {
            if UIApplication.sharedApplication().isIgnoringInteractionEvents() {
                UIApplication.sharedApplication().endIgnoringInteractionEvents()
                print("Offline")
            }
            return
        }
        
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()
        
        DataService.ds.REF_POSTS.observeSingleEventOfType(.Value, withBlock: { snapshot in
            
            if snapshot.hasChild(self.post!.postKey) {
                self.reportTapAction?(self)
            } else {
                NSNotificationCenter.defaultCenter().postNotificationName("update", object: nil)
            }
        })
        
        Async.background(after: 0.5) {
            if UIApplication.sharedApplication().isIgnoringInteractionEvents() {
                UIApplication.sharedApplication().endIgnoringInteractionEvents()
            }
        }
    }
}
