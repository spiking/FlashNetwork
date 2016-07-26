//
//  CommentsVC.swift
//  FabSocialNetwork
//
//  Created by Adam Thuvesen on 2016-06-09.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import UIKit
import Firebase
import JSSAlertView
import EZLoadingActivity
import Async

class CommentsVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    private var refreshControl: UIRefreshControl!
    private var comments = [Comment]()
    private var placeHolderText = "Leave a comment"
    private var reportedComment: Comment!
    private var blockedUsers = [String]()
    
    var post: Post!
    
    @IBOutlet weak var commentView: UIView!
    @IBOutlet weak var commentTextView: UITextView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var bottomSpaceConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        tableView.tableFooterView = UIView()
        
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(FeedVC.refresh(_:)), forControlEvents: UIControlEvents.ValueChanged)
        tableView.addSubview(refreshControl) // not required when using UITableViewController
        
        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableViewAutomaticDimension
        
        edgesForExtendedLayout = UIRectEdge.None
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(CommentsVC.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        // Be able to push view up/down when keyboard is shown, observers
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CommentsVC.keyboardWillShow(_:)), name:UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CommentsVC.keyboardWillHide(_:)), name:UIKeyboardWillHideNotification, object: nil)
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Plain, target:nil, action:nil)
        
        commentTextView.delegate = self
        
        NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: #selector(CommentsVC.isConnected), userInfo: nil, repeats: true)
        
        title = "COMMENTS"
        
        loadBlockedUsersAndInitalDataFromFirebase()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        
        if UIApplication.sharedApplication().isIgnoringInteractionEvents() {
            UIApplication.sharedApplication().endIgnoringInteractionEvents()
        }
        
        if commentTextView.text == "" {
            commentTextView.text = placeHolderText
            commentTextView.textColor = UIColor.lightGrayColor()
        } else {
            commentTextView.textColor = UIColor.whiteColor()
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        switch segue.identifier {
        case SEGUE_OTHERUSERPROFILEVC?:
            if let otherUserProfileVC = segue.destinationViewController as? OtherUserProfileVC {
                if let userKey = sender as? String {
                    otherUserProfileVC.otherUserKey = userKey
                }
            }
        case SEGUE_PROFILEVC?:
            print("Profile")
        default:
            break
        }
    }
    
    func loadBlockedUsersAndInitalDataFromFirebase() {
        DataService.ds.REF_USER_CURRENT.child("blocked_users").observeEventType(.Value, withBlock: { snapshot in
            
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                for snap in snapshot {
                    self.blockedUsers.append(snap.key)
                }
            }
            
            self.loadCommentsFromFirebase()
        })
    }
    
    func loadCommentsFromFirebase() {
        
        DataService.ds.REF_COMMENTS.queryOrderedByChild("post").queryEqualToValue(self.post.postKey).observeEventType(.Value, withBlock: { snapshot in
            self.comments = []
            
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                for snap in snapshot {
                    if let commentDict = snap.value as? Dictionary<String, AnyObject> {
                        let key = snap.key
                        let comment = Comment(commentKey: key, dictionary: commentDict)
                        
                        if !self.blockedUsers.contains(comment.userKey) {
                            self.comments.append(comment)
                        }
                    }
                }
            }
            
            self.tableView.reloadData()
        })
    }
    
    func isConnected() {
        
        if !isConnectedToNetwork() {
            tableView.reloadData()
        }
        
        if isConnectedToNetwork() && comments.count == 0 {
            tableView.reloadData()
        }
    }
    
    func refresh(sender:AnyObject) {
        
        if isConnectedToNetwork() {
            tableView.reloadData()
            refreshControl.endRefreshing()
        } else {
            refreshControl.endRefreshing()
            JSSAlertView().danger(self, title: "No Internet Connection", text: "Please connect to a network and try again.")
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if let cell = tableView.dequeueReusableCellWithIdentifier("CommentCell") as? CommentCell {
            
            // Cancel request if user scrolls
            cell.request?.cancel()
            let comment = comments[indexPath.row]
            cell.configureCell(comment)
            
            let backgroundView = UIView()
            backgroundView.backgroundColor = UIColor.blackColor()
            cell.selectedBackgroundView = backgroundView
            
            cell.blockUserTapAction = { (cell) in
                self.performSegueWithIdentifier(SEGUE_OTHERUSERPROFILEVC, sender: comment.userKey)
            }
            
            cell.usernameTapAction = { (cell) in
                
                if comment.userKey != currentUserKey() {
                    self.performSegueWithIdentifier(SEGUE_OTHERUSERPROFILEVC, sender: comment.userKey)
                } else {
                    self.performSegueWithIdentifier(SEGUE_PROFILEVC, sender: comment.userKey)
                }
                
            }
            
            cell.profileImgTapAction = { (cell) in
                
                if comment.userKey != currentUserKey() {
                    self.performSegueWithIdentifier(SEGUE_OTHERUSERPROFILEVC, sender: comment.userKey)
                } else {
                    self.performSegueWithIdentifier(SEGUE_PROFILEVC, sender: comment.userKey)
                }
                
            }
            
            return cell
        } else {
            return CommentCell()
        }
        
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let reportAction = UITableViewRowAction(style: .Normal, title: "Report") { (rowAction:UITableViewRowAction, indexPath:NSIndexPath) -> Void in
            self.reportAlert()
            self.reportedComment = self.comments[indexPath.row]
        }
        
        reportAction.backgroundColor = UIColor.darkGrayColor()
        
        let deleteAction = UITableViewRowAction(style: .Normal, title: "Remove") { (rowAction:UITableViewRowAction, indexPath:NSIndexPath) -> Void in
            
            if !isConnectedToNetwork() {
                JSSAlertView().danger(self, title: "No Internet Connection", text: "Your comment will be removed when connected to a network.")
                tableView.setEditing(false, animated: true)
            }
            
            let commentToRemove = self.comments[indexPath.row]
            self.removeComment(commentToRemove)
            self.comments.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
        }
        
        deleteAction.backgroundColor = UIColorFromHex(0xe64c3c, alpha: 1)
        
        let comment = comments[indexPath.row]
        
        if comment.userKey == currentUserKey() {
            return [deleteAction]
        } else {
            return [reportAction]
        }
    }
    
    func textViewShouldBeginEditing(textView: UITextView) -> Bool {
        commentTextView.textColor = UIColor.whiteColor()
        
        if commentTextView.text == placeHolderText {
            commentTextView.text = ""
        }
        
        return true
    }
    
    
    func textViewDidEndEditing(textView: UITextView) {
        
        if commentTextView.text == "" {
            commentTextView.text = placeHolderText
            commentTextView.textColor = UIColor.lightGrayColor()
        }
    }
    
    func addComment(comment: String!) {
        
        let currentPostKey = post.postKey
        let comment : Dictionary<String, String> = ["user" : currentUserKey(), "post": currentPostKey, "comment" : comment!, "timestamp": Timestamp]
        
        DataService.ds.REF_COMMENTS.childByAutoId().setValue(comment)
    }
    
    // Dismiss keyboard on tap gesture
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func keyboardWillShow(sender: NSNotification) {
        var info = sender.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        
        UIView.animateWithDuration(0.1, animations: { () -> Void in
            self.commentTextView.scrollEnabled = true
            self.bottomSpaceConstraint.constant = keyboardFrame.size.height
        })
    }
    
    func keyboardWillHide(sender: NSNotification) {
        self.commentTextView.scrollEnabled = false
        self.bottomSpaceConstraint.constant =  0
    }
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        var str = ""
        if isConnectedToNetwork() {
            str = "No Comments"
        } else {
            str = "No Internet Connection"
        }
        
        let attrs = [NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)]
        return NSAttributedString(string: str, attributes: attrs)
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        var str = ""
        if isConnectedToNetwork() {
            str = "It looks like there are no comments on this post. If you like, add one below."
        } else {
            str = "Please connect to a network. The comments will load automatically."
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
    
    func removeComment(commentToRemove: Comment!) {
        
        DataService.ds.REF_COMMENTS.child(commentToRemove.commentKey).removeValueWithCompletionBlock { (error, ref) in
            
            if error != nil {
                EZLoadingActivity.showWithDelay("Failure", disableUI: true, seconds: 1.0)
                EZLoadingActivity.Settings.SuccessText = "Failure"
                EZLoadingActivity.hide(success: false, animated: true)
            } else {
                EZLoadingActivity.showWithDelay("Removed", disableUI: true, seconds: 1.0)
                EZLoadingActivity.Settings.FailText = "Removed"
                EZLoadingActivity.hide(success: false, animated: true)
            }
        }
    }
    
    func reportAlert() {
        let alertview = JSSAlertView().show(self, title: "Report", text: "Do you want to report this user for abusive behaviour?", buttonText: "Yes", cancelButtonText: "No", color: UIColorFromHex(0xe64c3c, alpha: 1))
        alertview.setTextTheme(.Light)
        alertview.addAction(answeredYes)
        alertview.addCancelAction(answeredNo)
        tableView.setEditing(false, animated: true)
    }
    
    func answeredYes() {
        reportUserComment()
    }
    
    func answeredNo() {
        // Do nothing
    }
    
    func reportUserComment() {
        
        let reportCommentRef = DataService.ds.REF_REPORTED_COMMENTS.child(self.reportedComment.commentKey)
        
        // Like observer
        reportCommentRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
            
            // If no report exist, create one
            if (snapshot.value as? NSNull) != nil {
                
                let comment: Dictionary<String, AnyObject> = [
                    "comment" : self.reportedComment.commentKey,
                    "report_time" : Timestamp,
                    "report_count" : 1,
                ]
                
                reportCommentRef.setValue(comment)
                reportCommentRef.child("reports_from_users").child(currentUserKey()).setValue(Timestamp)
                
            } else {
                
                reportCommentRef.child("reports_from_users").child(currentUserKey()).setValue(Timestamp)
                
                // Should be put on server side
                if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                    for snap in snapshot {
                        if let commentDict = snap.value as? Dictionary<String, AnyObject> {
                            if commentDict[currentUserKey()] == nil {
                                let reportCount = commentDict.count + 1
                                reportCommentRef.child("report_count").setValue(reportCount)
                            }
                        }
                    }
                }
            }
        })
    }
    
    func postComment() {
        if commentTextView.text != "" && commentTextView.text != placeHolderText {
            dismissKeyboard()
            addComment(commentTextView.text)
            commentTextView.text = placeHolderText
            commentTextView.textColor = UIColor.lightGrayColor()
            self.sendPushNotificationToUser()
            tableView.reloadData()
            
            Async.main(after: 0.5) {
                if !isConnectedToNetwork() {
                    JSSAlertView().danger(self, title: "No Internet Connection", text: "Your message will be sent when connected to a network.")
                }
            }
        }
    }
    
    func sendPushNotificationToUser() {
        DataService.ds.REF_USERS.child(self.post!.userKey).observeSingleEventOfType(.Value) { (snapshot: FIRDataSnapshot!) in
            if let userPushId = snapshot.childSnapshotForPath("userPushId").value as? String {
                if self.post!.userKey != currentUserKey() {
                    let postTime = dateSincePosted(self.post!.timestamp)
                    if postTime != "" && postTime != " " {
                        oneSignal.postNotification(["contents": ["en":"\(getCurrentUsername().capitalizedString) commented on the post you uploaded \(postTime) ago."], "include_player_ids": [userPushId]])
                    } else {
                        oneSignal.postNotification(["contents": ["en":"\(getCurrentUsername().capitalizedString) ommented on the post you recently uploaded."], "include_player_ids": [userPushId]])
                    }
                }
            }
        }
    }
    
    @IBAction func commentBtnTapped(sender: AnyObject) {
        
        dismissKeyboard()
        
        if !userProfileAdded() {
            JSSAlertView().danger(self, title: "Update Your Profile", text: "Please add a profile image and username before commenting.")
            return
        }
        
        self.postComment()
    }
}
