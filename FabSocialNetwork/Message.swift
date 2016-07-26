//
//  Message.swift
//  FabSocialNetwork
//
//  Created by Adam Thuvesen on 2016-07-26.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import Foundation

class Message: Equatable {
    
    private var _senderId: String!
    private var _receiverId: String!
    private var _lastMessage: String!
    private var _lastMessageFromCurrentUser = false
    
    var senderId: String {
        return _senderId
    }
    
    var receiverId: String {
        return _receiverId
    }
    
    var lastMessage: String {
        return _lastMessage
    }
    
    var lastMessageFromCurrentUser: Bool {
        return _lastMessageFromCurrentUser
    }
    
    var getOtherUserId: String {
        
        if senderId == currentUserKey() {
            return receiverId
        } else {
            return senderId
        }
        
    }
    
    init(senderId: String, receiverId: String, lastMessage: String, lastMessageFromCurrentUser: Bool) {
        self._senderId = senderId
        self._receiverId = receiverId
        self._lastMessage = lastMessage
        self._lastMessageFromCurrentUser = lastMessageFromCurrentUser
    }
}

func == (lhs: Message, rhs: Message) -> Bool {
    if lhs.senderId == rhs.senderId && lhs.receiverId == rhs.receiverId || lhs.senderId == rhs.receiverId && lhs.receiverId == rhs.senderId {
        return true
    } else {
        return false
    }
}
