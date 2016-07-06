//
//  UserPostsVC.swift
//  FabSocialNetwork
//
//  Created by Adam Thuvesen on 2016-06-24.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import UIKit
import Firebase
import Alamofire
import EZLoadingActivity
import JSSAlertView

class UserPostsVC: UIViewController, UITableViewDelegate, UITableViewDataSource, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var userPosts = [Post]()
    var confirmRemove = false
    var indexPathRemove: NSIndexPath?
    var typeOfCell = TypeOfCell.UserPostCell
    var zoomBarButton : UIButton!
    
    enum TypeOfCell: String {
        case UserPostCell = "UserPostCell"
        case PostCell = "PostCell"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadUserPostsFromFirebase()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        
        let longpress = UILongPressGestureRecognizer(target: self, action: #selector(UserPostsVC.longPressGestureRecognized(_:)))
        tableView.addGestureRecognizer(longpress)
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Plain, target:nil, action:nil)
//        tableView.contentInset = UIEdgeInsetsMake(-8, 0, 0, 0);
        
        title = "POSTS"
        
        navigationItem.leftItemsSupplementBackButton = true
        let deleteButton = setupDeleteButton()
        let viewButton = setupViewButton()
        navigationItem.setRightBarButtonItems([deleteButton, viewButton], animated: true)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == SEGUE_COMMENTSVC {
            if let commentsVC = segue.destinationViewController as? CommentsVC {
                if let post = sender as? Post {
                    commentsVC.post = post
                }
            }
        }
        
        if segue.identifier == SEGUE_SHOWUSERPOSTVC {
            if let userPostVC = segue.destinationViewController as? ShowUserPostVC {
                if let post = sender as? Post {
                    userPostVC.post = post
                }
            }
        }
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        if typeOfCell == TypeOfCell.PostCell {
            typeOfCell = .UserPostCell
            tableView.reloadData()
        }
        
        if tableView.editing {
            tableView.setEditing(false, animated: true)
        } else {
            tableView.setEditing(true, animated: true)
        }
    }
    
    func setupDeleteButton() -> UIBarButtonItem {
        let button: UIButton = UIButton(type: UIButtonType.Custom)
        button.setImage(UIImage(named: "Trash"), forState: UIControlState.Normal)
        button.addTarget(self, action: #selector(UserPostsVC.setEditing(_:animated:)), forControlEvents: UIControlEvents.TouchUpInside)
        button.frame = CGRectMake(0, 0, 23, 23)
        let barButton = UIBarButtonItem(customView: button)

        return barButton
    }
    
    func setupViewButton() -> UIBarButtonItem {
        zoomBarButton = UIButton(type: UIButtonType.Custom)
        zoomBarButton.setImage(UIImage(named: "ZoomIn"), forState: UIControlState.Normal)
        zoomBarButton.addTarget(self, action: #selector(UserPostsVC.changeTypeOfCell), forControlEvents: UIControlEvents.TouchUpInside)
        zoomBarButton.frame = CGRectMake(0, 0, 23, 23)
        let barButton = UIBarButtonItem(customView: zoomBarButton)
        return barButton
    }
    
    func changeTypeOfCell() {
        if typeOfCell == TypeOfCell.UserPostCell {
            typeOfCell = .PostCell
            zoomBarButton.setImage(UIImage(named: "ZoomOut"), forState: UIControlState.Normal)
            
            if tableView.editing {
                tableView.setEditing(false, animated: true)
            }
            
        } else {
            typeOfCell = .UserPostCell
            zoomBarButton.setImage(UIImage(named: "ZoomIn"), forState: UIControlState.Normal)
        }
        
        tableView.reloadData()
    }
    
    func loadUserPostsFromFirebase() {
        let userKey = String(NSUserDefaults.standardUserDefaults().valueForKey(KEY_UID)!)
        
        DataService.ds.REF_POSTS.queryOrderedByChild("user").queryEqualToValue(userKey).observeEventType(.Value, withBlock: { snapshot in
            self.userPosts = []
            
            if let snapshot = snapshot.children.allObjects as? [FDataSnapshot] {
                for snap in snapshot {
                    if let postDict = snap.value as? Dictionary<String, AnyObject> {
                        let key = snap.key
                        let post = Post(postKey: key, dictionary: postDict)
                        self.userPosts.append(post)
                    }
                }
            }
            
            if self.userPosts.count == 0 {
                self.tableView.separatorStyle = UITableViewCellSeparatorStyle.None
            }
            
            self.tableView.reloadData()
        })
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        var str = ""
        if isConnectedToNetwork() {
            str = "It looks like you have not made any posts. Go back to the main view to create one."
        } else {
            str = "Please connect to a network and the feed will load automatically."
        }
        let attrs = [NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleBody)]
        return NSAttributedString(string: str, attributes: attrs)
    }
    
    func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage! {
        var imgName = ""
        
        if isConnectedToNetwork() {
            imgName = "Write"
        } else {
            imgName = "Wifi"
        }
        
        return UIImage(named: imgName)
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userPosts.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let post = userPosts[indexPath.row]
        
        if typeOfCell == TypeOfCell.PostCell {
            if post.imageUrl == nil || post.imageUrl == "" {
                return 115 + heightForView(post.postDescription, width: screenWidth - 51)
            } else {
                return 500 + heightForView(post.postDescription, width: screenWidth - 51)
            }
        } else {
            return 60
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if let cell = tableView.dequeueReusableCellWithIdentifier(typeOfCell.rawValue) as? UserPostCell {
            
            cell.request?.cancel()
            let post = userPosts[indexPath.row]
            var img: UIImage?
            
            if let url = post.imageUrl {
                img = FeedVC.imageCache.objectForKey(url) as? UIImage
            }
            
            cell.configureCell(post, img: img)
            
            let backgroundView = UIView()
            backgroundView.backgroundColor = UIColor.blackColor()
            cell.selectedBackgroundView = backgroundView
            
            return cell
        } else if let cell = tableView.dequeueReusableCellWithIdentifier(typeOfCell.rawValue) as? PostCell {
            
            cell.request?.cancel()
            let post = userPosts[indexPath.row]
            var img: UIImage?
            
            if let url = post.imageUrl {
                img = FeedVC.imageCache.objectForKey(url) as? UIImage
            }
            
            cell.configureCell(post, img: img)
            
            cell.commentTapAction = { (cell) in
                self.performSegueWithIdentifier(SEGUE_COMMENTSVC, sender: post)
            }
            
            cell.layoutIfNeeded()
            
            return cell
        } else {
            return UITableViewCell()
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        stopLikeAnimation()
    }
    
    func removeConfirmed() {
        
        let postToRemove = userPosts[indexPathRemove!.row]
        removePost(postToRemove)
        userPosts.removeAtIndex(indexPathRemove!.row)
        tableView.deleteRowsAtIndexPaths([indexPathRemove!], withRowAnimation: UITableViewRowAnimation.Automatic)
    }
    
    func removeNotConfirmed() {
        tableView.setEditing(false, animated: true)
    }
    
    func confirmRemovePost() {
        
        let alertview = JSSAlertView().show(self, title: "Are You Sure?", text: "Your post will be permanently removed.", buttonText: "Yes", cancelButtonText: "No", color: UIColorFromHex(0xe64c3c, alpha: 1))
        alertview.setTextTheme(.Light)
        alertview.addAction(removeConfirmed)
        alertview.addCancelAction(removeNotConfirmed)
        
    }
    
    func tableView(tableView: UITableView, titleForDeleteConfirmationButtonForRowAtIndexPath indexPath: NSIndexPath) -> String? {
        return "Remove"
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if typeOfCell == TypeOfCell.UserPostCell {
            let post = userPosts[indexPath.row]
            self.performSegueWithIdentifier(SEGUE_SHOWUSERPOSTVC, sender: post)
        }
    }
    
    func removePost(postToRemove: Post!) {
        
        DataService.ds.REF_POSTS.childByAppendingPath(postToRemove.postKey).removeValueWithCompletionBlock { (error, ref) in
            
            if error != nil {
                EZLoadingActivity.showWithDelay("Failure", disableUI: true, seconds: 1.0)
                EZLoadingActivity.Settings.SuccessText = "Failure"
                EZLoadingActivity.hide(success: false, animated: true)
            } else {
                EZLoadingActivity.showWithDelay("Removed", disableUI: true, seconds: 1.0)
                EZLoadingActivity.Settings.SuccessText = "Removed"
                EZLoadingActivity.hide(success: true, animated: true)
            }
        }
        
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if editingStyle == UITableViewCellEditingStyle.Delete {
            
            if !isConnectedToNetwork() {
                JSSAlertView().danger(self, title: "No Internet Connection", text: "Please connect to a network and try again.")
                tableView.setEditing(false, animated: true)
                return
            }
            
            indexPathRemove = indexPath
            confirmRemovePost()
            
        }
    }
    
    func longPressGestureRecognized(gestureRecognizer: UIGestureRecognizer) {
        
        let longPress = gestureRecognizer as! UILongPressGestureRecognizer
        let state = longPress.state
        let locationInView = longPress.locationInView(tableView)
        let indexPath = tableView.indexPathForRowAtPoint(locationInView)
        
        struct My {
            static var cellSnapshot : UIView? = nil
            static var cellIsAnimating : Bool = false
            static var cellNeedToShow : Bool = false
        }
        struct Path {
            static var initialIndexPath : NSIndexPath? = nil
        }
        
        switch state {
        case UIGestureRecognizerState.Began:
            if indexPath != nil {
                Path.initialIndexPath = indexPath
                let cell = tableView.cellForRowAtIndexPath(indexPath!) as UITableViewCell!
                My.cellSnapshot  = snapshotOfCell(cell)
                
                var center = cell.center
                My.cellSnapshot!.center = center
                My.cellSnapshot!.alpha = 0.0
                tableView.addSubview(My.cellSnapshot!)
                
                UIView.animateWithDuration(0.25, animations: { () -> Void in
                    center.y = locationInView.y
                    My.cellIsAnimating = true
                    My.cellSnapshot!.center = center
                    My.cellSnapshot!.transform = CGAffineTransformMakeScale(1.05, 1.05)
                    My.cellSnapshot!.alpha = 0.98
                    cell.alpha = 0.0
                    }, completion: { (finished) -> Void in
                        if finished {
                            My.cellIsAnimating = false
                            if My.cellNeedToShow {
                                My.cellNeedToShow = false
                                UIView.animateWithDuration(0.25, animations: { () -> Void in
                                    cell.alpha = 1
                                })
                            } else {
                                cell.hidden = true
                            }
                        }
                })
            }
            
        case UIGestureRecognizerState.Changed:
            if My.cellSnapshot != nil {
                var center = My.cellSnapshot!.center
                center.y = locationInView.y
                My.cellSnapshot!.center = center
                
                if ((indexPath != nil) && (indexPath != Path.initialIndexPath)) {
                    userPosts.insert(userPosts.removeAtIndex(Path.initialIndexPath!.row), atIndex: indexPath!.row)
                    tableView.moveRowAtIndexPath(Path.initialIndexPath!, toIndexPath: indexPath!)
                    Path.initialIndexPath = indexPath
                }
            }
        default:
            if Path.initialIndexPath != nil {
                let cell = tableView.cellForRowAtIndexPath(Path.initialIndexPath!) as UITableViewCell!
                if My.cellIsAnimating {
                    My.cellNeedToShow = true
                } else {
                    cell.hidden = false
                    cell.alpha = 0.0
                }
                
                UIView.animateWithDuration(0.25, animations: { () -> Void in
                    My.cellSnapshot!.center = cell.center
                    My.cellSnapshot!.transform = CGAffineTransformIdentity
                    My.cellSnapshot!.alpha = 0.0
                    cell.alpha = 1.0
                    
                    }, completion: { (finished) -> Void in
                        if finished {
                            Path.initialIndexPath = nil
                            My.cellSnapshot!.removeFromSuperview()
                            My.cellSnapshot = nil
                        }
                })
            }
        }
    }
    
    func snapshotOfCell(inputView: UIView) -> UIView {
        UIGraphicsBeginImageContextWithOptions(inputView.bounds.size, false, 0.0)
        inputView.layer.renderInContext(UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext() as UIImage
        UIGraphicsEndImageContext()
        
        let cellSnapshot : UIView = UIImageView(image: image)
        cellSnapshot.layer.masksToBounds = false
        cellSnapshot.layer.cornerRadius = 0.0
        cellSnapshot.layer.shadowOffset = CGSizeMake(-5.0, 0.0)
        cellSnapshot.layer.shadowRadius = 5.0
        cellSnapshot.layer.shadowOpacity = 0.4
        return cellSnapshot
    }

}