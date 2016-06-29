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
    
    @IBOutlet weak var descLblHeight: NSLayoutConstraint!
    @IBOutlet weak var likesLblWidth: NSLayoutConstraint!
    @IBOutlet weak var profileImg: UIImageView!
    @IBOutlet weak var mainImg: UIImageView!
    @IBOutlet weak var descriptionLbl: UILabel!
    @IBOutlet weak var likesLbl: UILabel!
    @IBOutlet weak var likesLblText: UILabel!
    @IBOutlet weak var likeImage: UIImageView!
    @IBOutlet weak var usernameLbl: UILabel!
    @IBOutlet weak var commentsBtn: UIButton!
    @IBOutlet weak var timeLbl: UILabel!
    
    var commentTapAction: ((UITableViewCell) -> Void)?
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
        
        let date = NSDate(timeIntervalSince1970: Double(post.timestamp)!)
        let dateDiff = NSDate().offsetFrom(date)
        self.timeLbl.text = dateDiff
        
        self.likesLblWidth.constant = self.likesLbl.intrinsicContentSize().width + 4
        
        self.userRef = DataService.ds.REF_USERS.childByAppendingPath(post.userKey)
        self.likeRef = DataService.ds.REF_USER_CURRENT.childByAppendingPath("likes").childByAppendingPath(post.postKey)
        self.userLikes = DataService.ds.REF_USER_CURRENT.childByAppendingPath("likes")
        
        let height = heightForView(post.postDescription, width: screenWidth - 51)
        self.descLblHeight.constant = height
        
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
                        FeedVC.imageCache.setObject(img, forKey: self.post!.imageUrl!)
                    }
                })
            }
        } else {
            self.mainImg.hidden = true
        }
        
        // Profile image
        userRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
            
            if let username = snapshot.value["username"] as? String {
                self.usernameLbl.text = username.capitalizedString
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
                self.profileImg.image = UIImage(named:"profile2.png")
            }
            
            
            }, withCancelBlock: { error in
                print(error.description)
        })
        
        // If current post exist in current users likes, set heart to full (needed for reinstall)

        userLikes.observeSingleEventOfType(.Value, withBlock: { snapshot in
    
            if snapshot.hasChild(post.postKey) {
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
    
    func mainImgTapped(sender: UITapGestureRecognizer) {
        
        if !userLikedPost {
            startLikeAnimation(self)
            likeTapped(sender)
        }
    }
    
    @IBAction func commentsBtnTapped(sender: AnyObject) {
        commentTapAction?(self)
    }
    
}
