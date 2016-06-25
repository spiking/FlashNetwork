//
//  Alerts.swift
//  FabSocialNetwork
//
//  Created by Adam Thuvesen on 2016-06-10.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import Foundation
import SCLAlertView
import EZLoadingActivity
import JSSAlertView
import MBProgressHUD

// Global alert functions

func heightForView(text:String, width:CGFloat) -> CGFloat {
    let label:UILabel = UILabel(frame: CGRectMake(0, 0, width, CGFloat.max))
    label.numberOfLines = 0
    label.lineBreakMode = NSLineBreakMode.ByWordWrapping
    label.text = text
    label.sizeToFit()
    
    return label.frame.height
}

var Timestamp: String {
    return "\(NSDate().timeIntervalSince1970 * 1)"
}

var likeAnimation = MBProgressHUD()

func userProfileAdded() -> Bool {
    return NSUserDefaults.standardUserDefaults().objectForKey("profileUrl") != nil  && NSUserDefaults.standardUserDefaults().objectForKey("username") != nil
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

func waitAlert(title: String, subTitle: String) {
    
    SCLAlertView().showTitle(
        title,
        subTitle: subTitle,
        duration: 3.0,
        completeText: "Ok",
        style: .Wait,
        colorStyle: 0x1C1C1C,
        colorTextButton: 0xFFFFFF
    )
}

func successAlert(title: String, subTitle: String) {
    SCLAlertView().showTitle(
        title,
        subTitle: subTitle,
        duration: 3.0,
        completeText: "Done",
        style: .Success,
        colorStyle: 0x6AE368,
        colorTextButton: 0xFFFFFF
    )
}

func successAlertTest(title: String, subTitle: String) {
    SCLAlertView().showTitle(
        title,
        subTitle: subTitle,
        duration: 3.0,
        completeText: "Done",
        style: .Success,
        colorStyle: 0x6AE368,
        colorTextButton: 0xFFFFFF
    )
}

func errorAlert(title: String, subTitle: String) {
    SCLAlertView().showTitle(
        title,
        subTitle: subTitle,
        duration: 3.0,
        completeText: "Ok",
        style: .Error,
        colorStyle: 0xCC2214,
        colorTextButton: 0xFFFFFF
    )
}

func infoAlert(title: String, subTitle: String) {
    SCLAlertView().showTitle(
        title,
        subTitle: subTitle,
        duration: 3.0,
        completeText: "Ok",
        style: .Info,
        colorStyle: 0xFF6F00,
        colorTextButton: 0xFFFFFF
    )
}


func alertViewSetup() {
    EZLoadingActivity.Settings.BackgroundColor = UIColor.blackColor()
    EZLoadingActivity.Settings.TextColor = UIColor.whiteColor()
    EZLoadingActivity.Settings.FontName = "Avenir"
    EZLoadingActivity.Settings.ActivityColor = UIColor.whiteColor()
    EZLoadingActivity.Settings.SuccessColor = UIColor(red: 37/255, green: 193/255, blue: 81/255, alpha: 0.88)
}

func successAlertNew(vc: UIViewController, title: String, msg: String) {
    let alertview = JSSAlertView().show(vc, title: title, text: msg, buttonText: "Ok", color: UIColorFromHex(0x25c151, alpha: 1))
    alertview.setTextTheme(.Light)
    alertview.setTitleFont("Avenir-Heavy")
    alertview.setTextFont("Avenir-Light")
    alertview.setButtonFont("Avenir-Heavy")
}
