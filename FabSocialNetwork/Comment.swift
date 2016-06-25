//
//  Comment.swift
//  FabSocialNetwork
//
//  Created by Adam Thuvesen on 2016-06-09.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import Foundation
import Firebase


class Comment {
    private var _commentText: String!
    private var _postKey: String!
    private var _userKey: String!
    private var _commentKey: String!
    private var _commentRef: Firebase!
    
    private var _postRef: Firebase!
    private var _userRef: Firebase!
    
    var commentText: String! {
        return _commentText
    }
    
    var postKey: String? {
        return _postKey
    }
    
    var userKey: String? {
        return _userKey
    }
    
    var commentKey: String? {
        return _commentKey
    }
    
    init(commentKey: String, dictionary: Dictionary<String, AnyObject>) {
        self._commentKey = commentKey
        
        if let commentText = dictionary["comment"] as? String {
            self._commentText = commentText
        }
        
        if let userKey = dictionary["user"] as? String {
            self._userKey = userKey
        }
        
        if let postKey = dictionary["post"] as? String {
            self._postKey = postKey
        }
        
        self._commentRef = DataService.ds.REF_COMMENTS.childByAppendingPath(self._commentKey)
    }
}

