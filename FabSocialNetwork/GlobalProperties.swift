//
//  GlobalProperties.swift
//  FabSocialNetwork
//
//  Created by Adam Thuvesen on 2016-07-11.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import Foundation
import MBProgressHUD

var oneSignal: OneSignal!
var firstLogin = true
var userBanned = false
var firstView = true
var iphoneType = ""
var likeAnimation = MBProgressHUD()
var Timestamp: String {
    return "\(NSDate().timeIntervalSince1970 * 1)"
}