//
//  Constants.swift
//  MySocialMedia
//
//  Created by Adam Thuvesen on 2016-06-02.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import Foundation
import UIKit

// SCREEN SIZES
let screenSize: CGRect = UIScreen.mainScreen().bounds
let screenWidth = screenSize.width

// KEYS
let KEY_UID = "uid"

// SEGUES
let SEGUE_LOGGED_IN = "feedVC"
let SEGUE_RESETPASSWORDVC = "resetPasswordVC"
let SEGUE_COMMENTSVC = "commentsVC"
let SEGUE_SETTINGSVC = "settingsVC"
let SEGUE_PROFILEVC = "profileVC"
let SEGUE_SHOWUSERPOSTVC = "showUserPostVC"
let SEGUE_USERAGREEMENTVC = "useragreementVC"
let SEGUE_OTHERUSERPROFILEVC = "otherUserProfileVC"
let SEGUE_CHATVC = "chatVC"
let SEGUE_ALLUSERPOSTSVC = "allUserPostsVC"
let SEGUE_FAVORITESVC = "favoritesVC"
let SEGUE_MESSAGEVC = "messageVC"

// STATUS CODES
let STATUS_ACCOUNT_NONEXIST = 17011
let STATUS_SENSITIVE_DATA_CHANGE = 17014
let STATUS_WEAK_PASSWORD = 17026
let STATUS_ACCOUNT_FIREBASE_AUTH = -6

