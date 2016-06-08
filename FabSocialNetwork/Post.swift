//
//  Post.swift
//  FabSocialNetwork
//
//  Created by Adam Thuvesen on 2016-06-05.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import Foundation
import Firebase

class Post {
    private var _postDescription: String!
    private var _imageUrl: String?
    private var _profileUrl: String?
    private var _likes: Int!
    private var _postKey: String!
    private var _postRef: Firebase!
    
    private var _userKey: String!
    
    var postDescription: String! {
        return _postDescription
    }
    
    var imageUrl: String? {
        return _imageUrl
    }
    
    var profileUrl: String? {
        return _profileUrl
    }
    
    var likes: Int! {
        return _likes
    }
    
    var postKey: String {
        return _postKey
    }
    
    var userKey: String {
        if _userKey != nil {
            return _userKey
        }
        return ""
    }
    
    init(postKey: String, dictionary: Dictionary<String, AnyObject>) {
        self._postKey = postKey
        
        if let likes = dictionary["likes"] as? Int {
            self._likes = likes
        }
        
        if let imgUrl = dictionary["imageUrl"] as? String {
            self._imageUrl = imgUrl
        }
        
        if let profileUrl = dictionary["profileUrl"] as? String {
            self._profileUrl = profileUrl
        }
        
        if let desc = dictionary["description"] as? String {
            self._postDescription = desc
        }
        
        if let user = dictionary["user"] as? String {
            self._userKey = user
        }
        
        self._postRef = DataService.ds.REF_POSTS.childByAppendingPath(self._postKey)
    }
    
    func adjustLikes(addLike: Bool) {
        if addLike {
            _likes = _likes + 1
        } else {
            _likes = _likes - 1
        }
        
        _postRef.childByAppendingPath("likes").setValue(_likes)
    }
}
