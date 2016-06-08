//
//  User.swift
//  FabSocialNetwork
//
//  Created by Adam Thuvesen on 2016-06-07.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import Foundation

class User {
    private var _username: String?
    private var _imageUrl: String?
    
    init(username: String?, imageUrl: String?) {
        _username = username
        _imageUrl = imageUrl
    }
    
    var username: String? {
        return _username
    }
    
    var imageUrl: String? {
        return _imageUrl
    }
}