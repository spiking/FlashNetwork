//
//  GlobalAlerts.swift
//  FabSocialNetwork
//
//  Created by Adam Thuvesen on 2016-07-11.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import Foundation
import EZLoadingActivity
import JSSAlertView

func alertViewSetup() {
    EZLoadingActivity.Settings.BackgroundColor = UIColor.blackColor()
    EZLoadingActivity.Settings.TextColor = UIColor.whiteColor()
    EZLoadingActivity.Settings.FontName = "Avenir"
    EZLoadingActivity.Settings.ActivityColor = UIColor.whiteColor()
    EZLoadingActivity.Settings.SuccessColor = UIColor(red: 37/255, green: 193/255, blue: 81/255, alpha: 0.88)
}

func successAlertFeedVC(vc: FeedVC, title: String, msg: String) {
    let alertview = JSSAlertView().show(vc, title: title, text: msg, buttonText: "Ok", color: UIColorFromHex(0x25c151, alpha: 1))
    alertview.setTextTheme(.Light)
    alertview.setTitleFont("Avenir-Heavy")
    alertview.setTextFont("Avenir-Medium")
    alertview.setButtonFont("Avenir-Heavy")
}

func successAlertSettingsVC(vc: SettingsVC, title: String, msg: String) {
    let alertview = JSSAlertView().show(vc, title: title, text: msg, buttonText: "Ok", color: UIColorFromHex(0x25c151, alpha: 1))
    alertview.setTextTheme(.Light)
    alertview.setTitleFont("Avenir-Heavy")
    alertview.setTextFont("Avenir-Medium")
    alertview.setButtonFont("Avenir-Heavy")
}

func successAlertResetPasswordVC(vc: ResetPasswordVC, title: String, msg: String) {
    let alertview = JSSAlertView().show(vc, title: title, text: msg, buttonText: "Ok", color: UIColorFromHex(0x25c151, alpha: 1))
    alertview.setTextTheme(.Light)
    alertview.setTitleFont("Avenir-Heavy")
    alertview.setTextFont("Avenir-Medium")
    alertview.setButtonFont("Avenir-Heavy")
}