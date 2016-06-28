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

// Global functions and variables

var likeAnimation = MBProgressHUD()

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

extension NSDate {
    func yearsFrom(date: NSDate) -> Int {
        return NSCalendar.currentCalendar().components(.Year, fromDate: date, toDate: self, options: []).year
    }
    func monthsFrom(date: NSDate) -> Int {
        return NSCalendar.currentCalendar().components(.Month, fromDate: date, toDate: self, options: []).month
    }
    func weeksFrom(date: NSDate) -> Int {
        return NSCalendar.currentCalendar().components(.WeekOfYear, fromDate: date, toDate: self, options: []).weekOfYear
    }
    func daysFrom(date: NSDate) -> Int {
        return NSCalendar.currentCalendar().components(.Day, fromDate: date, toDate: self, options: []).day
    }
    func hoursFrom(date: NSDate) -> Int {
        return NSCalendar.currentCalendar().components(.Hour, fromDate: date, toDate: self, options: []).hour
    }
    func minutesFrom(date: NSDate) -> Int{
        return NSCalendar.currentCalendar().components(.Minute, fromDate: date, toDate: self, options: []).minute
    }
    func secondsFrom(date: NSDate) -> Int{
        return NSCalendar.currentCalendar().components(.Second, fromDate: date, toDate: self, options: []).second
    }
    func offsetFrom(date: NSDate) -> String {
        print("CHECKING DATE")
        if yearsFrom(date)   > 0 { return "\(yearsFrom(date)) y"   }
        if monthsFrom(date)  > 0 { return "\(monthsFrom(date)) M"  }
        if weeksFrom(date)   > 0 { return "\(weeksFrom(date)) w"   }
        if daysFrom(date)    > 0 { return "\(daysFrom(date)) d"    }
        if hoursFrom(date)   > 0 { return "\(hoursFrom(date)) h"   }
        if minutesFrom(date) > 0 { return "\(minutesFrom(date)) m" }
        if secondsFrom(date) > 0 { return "\(secondsFrom(date)) s" }
        return ""
    }
    
    func offsetFromTest(date:NSDate) -> String {
        
        let dayHourMinuteSecond: NSCalendarUnit = [.Day, .Hour, .Minute, .Second]
        let difference = NSCalendar.currentCalendar().components(dayHourMinuteSecond, fromDate: date, toDate: self, options: [])
        
        let seconds = "\(difference.second)s"
        let minutes = "\(difference.minute)m" + " " + seconds
        let hours = "\(difference.hour)h" + " " + minutes
        let days = "\(difference.day)d" + " " + hours
        
        if difference.day    > 0 { return days }
        if difference.hour   > 0 { return hours }
        if difference.minute > 0 { return minutes }
        if difference.second > 0 { return seconds }
        return ""
    }
    
}


