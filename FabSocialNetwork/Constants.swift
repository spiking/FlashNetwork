//
//  Constants.swift
//  MySocialMedia
//
//  Created by Adam Thuvesen on 2016-06-02.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import Foundation
import UIKit

// Screen size
let screenSize: CGRect = UIScreen.mainScreen().bounds
let screenWidth = screenSize.width

// Keys
let KEY_UID = "uid"

//Segues
let SEGUE_LOGGED_IN = "feedVC"
let SEGUE_RESETPASSWORDVC = "resetPasswordVC"
let SEGUE_COMMENTSVC = "commentsVC"
let SEGUE_SETTINGSVC = "settingsVC"
let SEGUE_PROFILEVC = "profileVC"
let SEGUE_SHOWUSERPOSTVC = "showUserPostVC"
let SEGUE_USERAGREEMENTVC = "useragreementVC"
let SEGUE_OTHERUSERPROFILEVC = "otherUserProfileVC"
let SEGUE_CHATVC = "chatVC"

// Status Codes
let STATUS_ACCOUNT_NONEXIST = -8
let STATUS_ACCOUNT_FIREBASE_AUTH = -6

