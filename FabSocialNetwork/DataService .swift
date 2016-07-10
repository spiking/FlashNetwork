//
//  DataService.swift
//  MySocialMedia
//
//  Created by Adam Thuvesen on 2016-06-02.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.

import Foundation
import Firebase

let URL_BASE = "https://fabsocialnetwork.firebaseio.com"

class DataService {
    static let ds =  DataService()
    
    private var _REF_BASE = Firebase(url: "\(URL_BASE)")
    private var _REF_POSTS = Firebase(url: "\(URL_BASE)/posts")
    private var _REF_USERS = Firebase(url: "\(URL_BASE)/users")
    private var _REF_COMMENTS = Firebase(url:  "\(URL_BASE)/comments")
    private var _REF_REPORTED_COMMENTS = Firebase(url:  "\(URL_BASE)/reported_comments")
    private var _REF_REPORTED_POSTS = Firebase(url:  "\(URL_BASE)/reported_posts")
    
    var REF_BASE: Firebase {
        return _REF_BASE
    }
    
    var REF_POSTS: Firebase {
        return _REF_POSTS
    }
    
    var REF_USERS: Firebase {
        return _REF_USERS
    }
    
    var REF_COMMENTS: Firebase {
        return _REF_COMMENTS
    }
    
    var REF_REPORTED_COMMENTS: Firebase {
        return _REF_REPORTED_COMMENTS
    }
    
    var REF_REPORTED_POSTS: Firebase {
        return _REF_REPORTED_POSTS
    }
    
    var REF_USER_CURRENT: Firebase {
        let uid = NSUserDefaults.standardUserDefaults().valueForKey(KEY_UID) as! String
        let user = Firebase(url: "\(URL_BASE)").childByAppendingPath("users").childByAppendingPath(uid)
        
        return user!
    }
    
    func createFirebaseUser(uid: String, user: Dictionary<String, AnyObject>) {
        REF_USERS.childByAppendingPath(uid).setValue(user)
    }
}
