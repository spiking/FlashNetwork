//
//  Alerts.swift
//  FabSocialNetwork
//
//  Created by Adam Thuvesen on 2016-06-10.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import Foundation
import EZLoadingActivity
import JSSAlertView
import MBProgressHUD

// Global functions and variables

var likeAnimation = MBProgressHUD()

var Timestamp: String {
    return "\(NSDate().timeIntervalSince1970 * 1)"
}

func heightForView(text:String, width:CGFloat) -> CGFloat {
    let label:UILabel = UILabel(frame: CGRectMake(0, 0, width, CGFloat.max))
    label.numberOfLines = 0
    label.lineBreakMode = NSLineBreakMode.ByWordWrapping
    label.text = text
    label.sizeToFit()
    
    return label.frame.height * 0.75
}

func userProfileAdded() -> Bool {
    return NSUserDefaults.standardUserDefaults().objectForKey("username") != nil
}

func startLikeAnimation(view: UIView) {
    likeAnimation = MBProgressHUD.showHUDAddedTo(view, animated: true)
    likeAnimation.frame = CGRectMake(0, 0, 50, 50)
    likeAnimation.mode = MBProgressHUDMode.CustomView
    let image = UIImage(named: "Heart")
    likeAnimation.customView = UIImageView(image: image)
    likeAnimation.hide(true, afterDelay: 1.0)
}

func stopLikeAnimation() {
    likeAnimation.hide(false)
}

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

func successAlertsSettingsVC(vc: SettingsVC, title: String, msg: String) {
    let alertview = JSSAlertView().show(vc, title: title, text: msg, buttonText: "Ok", color: UIColorFromHex(0x25c151, alpha: 1))
    alertview.setTextTheme(.Light)
    alertview.setTitleFont("Avenir-Heavy")
    alertview.setTextFont("Avenir-Medium")
    alertview.setButtonFont("Avenir-Heavy")
}
