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
import Async

// Global functions and variables

var firstLogin = true
var userBanned = false
var likeAnimation = MBProgressHUD()

func isUserAuthenticated(vc: UIViewController) {
    
    DataService.ds.REF_USERS.observeEventType(.Value, withBlock: { snapshot in
        
        if snapshot.hasChild(currentUserKey()) {
            userBanned = false
        } else {
            userBanned = true
            
            let appDomain = NSBundle.mainBundle().bundleIdentifier!
            NSUserDefaults.standardUserDefaults().removePersistentDomainForName(appDomain)
            
            let loginVC: UIViewController? = vc.storyboard?.instantiateViewControllerWithIdentifier("InitalNavigationController")
            vc.presentViewController(loginVC!, animated: true, completion: nil)
        }
        
    })
}

func isVisible(view: UIView) -> Bool {
    func isVisible(view: UIView, inView: UIView?) -> Bool {
        guard let inView = inView else { return true }
        let viewFrame = inView.convertRect(view.bounds, fromView: view)
        if CGRectIntersectsRect(viewFrame, inView.bounds) {
            return isVisible(view, inView: inView.superview)
        }
        return false
    }
    return isVisible(view, inView: view.superview)
}

var Timestamp: String {
    return "\(NSDate().timeIntervalSince1970 * 1)"
}

func heightForView(text:String, width:CGFloat) -> CGFloat {
    let label:UILabel = UILabel(frame: CGRectMake(0, 0, width, CGFloat.max))
    label.numberOfLines = 0
    label.lineBreakMode = NSLineBreakMode.ByWordWrapping
    label.text = text
    label.sizeToFit()
    
    return label.frame.height * 0.80
}

func currentUserKey() -> String {
    if let currentUser = NSUserDefaults.standardUserDefaults().valueForKey(KEY_UID) as? String {
        return currentUser
    } else {
        return "Unknown User"
    }
}

func userProfileAdded() -> Bool {
    return NSUserDefaults.standardUserDefaults().objectForKey("username") != nil
}

func userAcceptedTerms() -> Bool {
    return NSUserDefaults.standardUserDefaults().valueForKey("terms") as? String == "TRUE"
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
