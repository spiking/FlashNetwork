//
//  DataService.swift
//  MySocialMedia
//
//  Created by Adam Thuvesen on 2016-06-02.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.

import Foundation
import Firebase

let URL_BASE = FIRDatabase.database().reference()

class DataService {
    
    static let ds =  DataService()
    
    private var _REF_BASE = URL_BASE
    private var _REF_POSTS = URL_BASE.child("posts")
    private var _REF_USERS = URL_BASE.child("users")
    private var _REF_COMMENTS = URL_BASE.child("comments")
    private var _REF_REPORTED_COMMENTS = URL_BASE.child("reported_comments")
    private var _REF_REPORTED_POSTS = URL_BASE.child("reported_posts")
    private var _REF_MESSAGES = URL_BASE.child("messages")
    
    var REF_BASE: FIRDatabaseReference {
        return _REF_BASE
    }
    
    var REF_POSTS: FIRDatabaseReference {
        return _REF_POSTS
    }
    
    var REF_USERS: FIRDatabaseReference {
        return _REF_USERS
    }
    
    var REF_COMMENTS: FIRDatabaseReference {
        return _REF_COMMENTS
    }
    
    var REF_REPORTED_COMMENTS: FIRDatabaseReference {
        return _REF_REPORTED_COMMENTS
    }
    
    var REF_REPORTED_POSTS: FIRDatabaseReference {
        return _REF_REPORTED_POSTS
    }
    
    var REF_MESSAGES: FIRDatabaseReference {
        return _REF_MESSAGES
    }
    
    var REF_USER_CURRENT: FIRDatabaseReference {
        let uid = NSUserDefaults.standardUserDefaults().valueForKey(KEY_UID) as! String
        let user = URL_BASE.child("users").child(uid)

        return user
    }
    
    func createFirebaseUser(uid: String, user: Dictionary<String, AnyObject>) {
        REF_USERS.child(uid).updateChildValues(user)
    }
}
