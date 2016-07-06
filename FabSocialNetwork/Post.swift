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
    private var _likes: Int!
    private var _postKey: String!
    private var _userKey: String!
    private var _timestamp: String!
    private var _postRef: Firebase!
    
    var postDescription: String! {
        return _postDescription
    }
    
    var imageUrl: String? {
        return _imageUrl
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
    
    var timestamp: String {
        if _timestamp != nil {
            return _timestamp
        }
        return "0"
    }
    
    init(postKey: String, dictionary: Dictionary<String, AnyObject>) {
        self._postKey = postKey
        
        if let likes = dictionary["likes"] as? Int {
            self._likes = likes
        }
        
        if let imgUrl = dictionary["imageUrl"] as? String {
            self._imageUrl = imgUrl
        }
        
        if let desc = dictionary["description"] as? String {
            self._postDescription = desc
        }
        
        if let user = dictionary["user"] as? String {
            self._userKey = user
        }
        
        if let timestamp = dictionary["timestamp"] as? String {
            self._timestamp = timestamp
        }
        
        self._postRef = DataService.ds.REF_POSTS.childByAppendingPath(self._postKey)
    }
    
    func adjustLikes(addLike: Bool) {
        if addLike {
            _likes = _likes + 1
            _postRef.childByAppendingPath("likes_from_users").childByAppendingPath(currentUserKey()).setValue(Timestamp)
        } else {
            _likes = _likes - 1
            _postRef.childByAppendingPath("likes_from_users").childByAppendingPath(currentUserKey()).removeValue()
            
        }
        _postRef.childByAppendingPath("likes").setValue(_likes)
    }
}
