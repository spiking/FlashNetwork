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

class PostCell: UITableViewCell {
    
    @IBOutlet weak var profileImg: UIImageView!
    @IBOutlet weak var mainImg: UIImageView!
    @IBOutlet weak var descriptionText: UITextView!
    @IBOutlet weak var likesLbl: UILabel!
    @IBOutlet weak var likeImage: UIImageView!
    @IBOutlet weak var usernameLbl: UILabel!
    
    var request: Request?
    var likeRef: Firebase!
    var userRef: Firebase!
    
    private var _post: Post?
    
    var post: Post? {
        return _post
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(PostCell.likeTapped(_:)))
        tap.numberOfTapsRequired = 1
        likeImage.addGestureRecognizer(tap)
        likeImage.userInteractionEnabled = true
        
        
    }
    
    override func drawRect(rect: CGRect) {
        profileImg.layer.cornerRadius = profileImg.frame.size.width / 2
        profileImg.clipsToBounds = true
        
        mainImg.clipsToBounds = true
    }
    
    
    func configureCell(post: Post, img: UIImage?) {
        
        self._post = post
        self.mainImg.image = nil
        self.descriptionText.text = post.postDescription
        self.likesLbl.text = "\(post.likes)"
        self.userRef = DataService.ds.REF_USERS.childByAppendingPath(post.userKey)
        
        self.likeRef = DataService.ds.REF_USER_CURRENT.childByAppendingPath("likes").childByAppendingPath(post.postKey)
        
        
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
        
        
        userRef.observeEventType(.Value, withBlock: { snapshot in
            print(snapshot.value)
            
            if let username = snapshot.value["username"] as? String {
                self.usernameLbl.text = username
                print(username)
            } else {
                self.usernameLbl.text = "Default Username"
            }
            
            if let profileUrl = snapshot.value["imgUrl"] as? String {
                
                print(profileUrl)
                
                // Not in cache, download and add to cache
                self.request = Alamofire.request(.GET, post.profileUrl!).validate(contentType: ["image/*"]).response(completionHandler: { (request, response, data, err) in
                    if err == nil {
                        let img = UIImage(data: data!)!
                        self.profileImg.image = img
                        FeedVC.imageCache.setObject(img, forKey: self.post!.profileUrl!)
                    }
                })
            } else {
                self.profileImg.hidden = true
            }
            
            
            }, withCancelBlock: { error in
                print(error.description)
        })
        
        likeRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
            
            // In snaphsot nil does not exist, instead you use NSNull
            if let doesNotExist = snapshot.value as? NSNull {
                self.likeImage.image = UIImage(named: "heart-empty")
            } else {
                self.likeImage.image = UIImage(named: "heart-full")
            }
        })
        
    }
    
    func likeTapped(sender: UITapGestureRecognizer) {
        
        likeRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
            
            //If I haven't like this, then like it, otherwise un-like it
            if let doesNotExist = snapshot.value as? NSNull {
                self.likeRef.setValue(true)
                self.likeImage.image = UIImage(named: "heart-full")
                self.post!.adjustLikes(true)
                
            } else {
                self.likeRef.removeValue()
                self.likeImage.image = UIImage(named: "heart-empty")
                self.post!.adjustLikes(false)
            }
            
            self.likesLbl.text = "\(self.post!.likes)"
        })
    }
}
