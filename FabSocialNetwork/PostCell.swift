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

class PostCell: UITableViewCell {
    
    @IBOutlet weak var profileImg: UIImageView!
    @IBOutlet weak var mainImg: UIImageView!
    @IBOutlet weak var descriptionLbl: UILabel!
    @IBOutlet weak var likesLbl: UILabel!
    @IBOutlet weak var likesLblText: UILabel!
    @IBOutlet weak var likeImage: UIImageView!
    @IBOutlet weak var usernameLbl: UILabel!
    @IBOutlet weak var commentsBtn: UIButton!
    
    var commentsTapAction: ((UITableViewCell) -> Void)?
    var request: Request?
    var likeRef: Firebase!
    var userRef: Firebase!
    var userLikes: Firebase!
    var userLikedPost = false
    
    private var _post: Post?
    
    var post: Post? {
        return _post
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let tapOnLike = UITapGestureRecognizer(target: self, action: #selector(PostCell.likeTapped(_:)))
        tapOnLike.numberOfTapsRequired = 1
        likeImage.addGestureRecognizer(tapOnLike)
        likeImage.userInteractionEnabled = true
        
        
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
        
        if post.likes == 1 {
            self.likesLblText.text = "Like"
        } else {
            self.likesLblText.text = "Likes"
        }
        
        self.userRef = DataService.ds.REF_USERS.childByAppendingPath(post.userKey)
        self.likeRef = DataService.ds.REF_USER_CURRENT.childByAppendingPath("likes").childByAppendingPath(post.postKey)
        self.userLikes = DataService.ds.REF_USER_CURRENT.childByAppendingPath("likes")
        
        // Main post image
        if post.imageUrl != nil {
            if img != nil {
                self.mainImg.image = img
            } else {
                // Not in cache, download and add to cache
                request = Alamofire.request(.GET, post.imageUrl!).validate(contentType: ["image/*"]).response(completionHandler: { (request, response, data, err) in
                    if err == nil {
                        let img = UIImage(data: data!)!
                        self.mainImg.image = img
                        print("Add to cache!")
                        FeedVC.imageCache.setObject(img, forKey: self.post!.imageUrl!)
                    }
                })
            }
        } else {
            self.mainImg.hidden = true
        }
        
        // Profile image
        userRef.observeEventType(.Value, withBlock: { snapshot in
            
            if let username = snapshot.value["username"] as? String {
                self.usernameLbl.text = username
            } else {
                self.usernameLbl.text = "Default Username"
            }
            
            if let profileUrl = snapshot.value["imgUrl"] as? String {
                if let profImage = FeedVC.imageCache.objectForKey(profileUrl) as? UIImage {
                    self.profileImg.image = profImage
                } else {
                    // Not in cache, download and add to cache
                    self.request = Alamofire.request(.GET, profileUrl).validate(contentType: ["image/*"]).response(completionHandler: { (request, response, data, err) in
                        if err == nil {
                            let img = UIImage(data: data!)!
                            self.profileImg.image = img
                            FeedVC.imageCache.setObject(img, forKey: profileUrl)
                        }
                    })

                }
                
            } else {
                print("No profile img")
                self.profileImg.hidden = true
            }
            
            
            }, withCancelBlock: { error in
                print(error.description)
        })
        
        // If current post exist in current users likes, set heart to full (needed for reinstall)
        userLikes.observeEventType(.Value, withBlock: { snapshot in
    
            if snapshot.hasChild(post.postKey) {
                print("Current user has liked this post!")
                self.likeImage.image = UIImage(named: "heart-full")
            }
        })
        
        // Like observer
        likeRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
            // In snaphsot nil does not exist, instead you use NSNull
            if (snapshot.value as? NSNull) != nil {
                self.likeImage.image = UIImage(named: "heart-empty")
                self.userLikedPost = false
            } else {
                self.likeImage.image = UIImage(named: "heart-full")
                self.userLikedPost = true
            }
        })
        
    }
    
    func likeTapped(sender: UITapGestureRecognizer) {
        
        likeRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
            
            //If I haven't like this, then like it, otherwise un-like it
            if (snapshot.value as? NSNull) != nil {
                self.likeRef.setValue(true)
                self.likeImage.image = UIImage(named: "heart-full")
                self.post!.adjustLikes(true)
                self.userLikedPost = true
            } else {
                self.likeRef.removeValue()
                self.likeImage.image = UIImage(named: "heart-empty")
                self.post!.adjustLikes(false)
                self.userLikedPost = false
            }
            
            self.likesLbl.text = "\(self.post!.likes)"
        })
    }
    
    
    @IBAction func commentsBtnTapped(sender: AnyObject) {
        print("Comments tapped!")
        commentsTapAction?(self)
    }
    
    func mainImgTapped(sender: UITapGestureRecognizer) {
        
        if !userLikedPost {
            let loadingNotification = MBProgressHUD.showHUDAddedTo(self.mainImg, animated: true)
            
            loadingNotification.frame = CGRectMake(0, 0, 50, 50)
            
            loadingNotification.mode = MBProgressHUDMode.CustomView
            let image = UIImage(named: "heart-full_50")
            loadingNotification.customView = UIImageView(image: image)
            loadingNotification.hide(true, afterDelay: 1.5)
            
            print("Images tapped!")
            likeTapped(sender)
        } else {
            print("User already liked this post!")
        }
        
    }
}
