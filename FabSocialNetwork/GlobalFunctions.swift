//
//  GlobalFunctions.swift
//  FabSocialNetwork
//
//  Created by Adam Thuvesen on 2016-07-11.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import Foundation
import MBProgressHUD
import Firebase

func dateSincePosted(timestamp: String) -> String {
    let dateCreated = NSDate(timeIntervalSince1970: Double(timestamp)!)
    let dateDiff = NSDate().offsetFrom(dateCreated)
    
    return dateDiff
}

func reportUserPost(postKey: String) {
    
    let reportPostRef = DataService.ds.REF_REPORTED_POSTS.childByAppendingPath(postKey)
    
    // Like observer
    reportPostRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
        
        // If no report exist, create one
        if (snapshot.value as? NSNull) != nil {
            
            let post: Dictionary<String, AnyObject> = [
                "post" : postKey,
                "report_time" : Timestamp,
                "report_count" : 1
            ]
            
            reportPostRef.setValue(post)
            reportPostRef.childByAppendingPath("reports_from_users").childByAppendingPath(currentUserKey()).setValue(Timestamp)
            
        } else {
            
            reportPostRef.childByAppendingPath("reports_from_users").childByAppendingPath(currentUserKey()).setValue(Timestamp)
            
            // Should be put on server side
            if let snapshot = snapshot.children.allObjects as? [FDataSnapshot] {
                for snap in snapshot {
                    if let postDict = snap.value as? Dictionary<String, AnyObject> {
                        if postDict[currentUserKey()] == nil {
                            let reportCount = postDict.count + 1
                            reportPostRef.childByAppendingPath("report_count").setValue(reportCount)
                        }
                    }
                }
            }
        }
    })
}

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

func checkiPhoneType() {
    if UIDevice().userInterfaceIdiom == .Phone {
        switch UIScreen.mainScreen().nativeBounds.height {
        case 480:
            print("iPhone Classic")
        case 960:
            print("iPhone 4 or 4S")
            iphoneType = "4"
        case 1136:
            print("iPhone 5 or 5S or 5C")
            iphoneType = "5"
        case 1334:
            print("iPhone 6 or 6S")
            iphoneType = "6"
        case 2208:
            print("iPhone 6+ or 6S+")
            iphoneType = "6+"
        default:
            print("unknown")
        }
    }
}

func delay(delay:Double, closure:()->()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), closure)
}

func heightForView(text:String, width:CGFloat) -> CGFloat {
    
    let label:UILabel = UILabel(frame: CGRectMake(0, 0, width, CGFloat.max))
    label.numberOfLines = 0
    label.lineBreakMode = NSLineBreakMode.ByWordWrapping
    label.font = UIFont(name: "Avenir-Book", size: 14)
    label.text = text
    label.sizeToFit()
    
    return label.frame.height
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