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

class CommentsVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    @IBOutlet weak var commentView: UIView!
    @IBOutlet weak var commentViewHeight: NSLayoutConstraint!
    @IBOutlet weak var commentTextViewHeight: NSLayoutConstraint!
    
    var refreshControl: UIRefreshControl!
    var post: Post!
    var comments = [Comment]()
    var placeHolderText = "Leave a comment"
    var noConnectionAlerts = 0
    var keyboardVisible = false
    var emojiClicked = false
    var reportedComment: Comment!
    
    @IBOutlet weak var stackViewHeight: NSLayoutConstraint!
    @IBOutlet weak var commentTextView: UITextView!
    @IBOutlet weak var tableView: UITableView!
    
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
        
        tableView.estimatedRowHeight = 75
        tableView.rowHeight = UITableViewAutomaticDimension
        
        edgesForExtendedLayout = UIRectEdge.None
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(CommentsVC.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        // Be able to push view up/down when keyboard is shown
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CommentsVC.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CommentsVC.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
        
        commentTextView.delegate = self
        
        NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: #selector(CommentsVC.isConnected), userInfo: nil, repeats: true)
        
        title = "COMMENTS"
        
        loadCommentsFromFirebase()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        
        if commentTextView.text == "" {
            commentTextView.text = placeHolderText
            commentTextView.textColor = UIColor.lightGrayColor()
        } else {
            commentTextView.textColor = UIColor.whiteColor()
        }
    }
    
    func loadCommentsFromFirebase() {
        
        DataService.ds.REF_COMMENTS.queryOrderedByChild("post").queryEqualToValue(self.post.postKey).observeEventType(.Value, withBlock: { snapshot in
            self.comments = []
            
            if let snapshot = snapshot.children.allObjects as? [FDataSnapshot] {
                for snap in snapshot {
                    if let commentDict = snap.value as? Dictionary<String, AnyObject> {
                        let key = snap.key
                        let comment = Comment(commentKey: key, dictionary: commentDict)
                        self.comments.append(comment)
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
            
            return cell
        } else {
            return CommentCell()
        }
        
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let reportAction = UITableViewRowAction(style: .Normal, title: "Report") { (rowAction:UITableViewRowAction, indexPath:NSIndexPath) -> Void in
            self.reportAlert()
            self.reportedComment = self.comments[indexPath.row]
            print("Report this post!")
        }
        reportAction.backgroundColor = UIColor.darkGrayColor()
        
        let deleteAction = UITableViewRowAction(style: .Normal, title: "Remove") { (rowAction:UITableViewRowAction, indexPath:NSIndexPath) -> Void in
            
            if !isConnectedToNetwork() {
                JSSAlertView().danger(self, title: "No Internet Connection", text: "Please connect to a network and try again.")
                tableView.setEditing(false, animated: true)
                return
            }
            
            let commentToRemove = self.comments[indexPath.row]
            self.removeComment(commentToRemove)
            self.comments.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
        }
        
        deleteAction.backgroundColor = UIColorFromHex(0xe64c3c, alpha: 1)
        
        let comment = comments[indexPath.row]
        
        if comment.userKey! == currentUserKey() {
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
    
    // Move view up
    func keyboardWillShow(notification: NSNotification) {
        
        // Emoji keyboard different height compared to normal keyboard
        if keyboardVisible {
            if !emojiClicked {
                self.view.frame.origin.y -= 40
                emojiClicked = true
            } else {
                self.view.frame.origin.y += 40
                emojiClicked = false
            }
            return
        }
        
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.CGRectValue() {
            self.view.frame.origin.y -= keyboardSize.height
            keyboardVisible = true
        }
    }
    
    // Move view down
    func keyboardWillHide(notification: NSNotification) {
        
        // Emoji keyboard different height compared to normal keyboard
        if !keyboardVisible {
            if emojiClicked {
                self.view.frame.origin.y += 40
                emojiClicked = false
            } else {
                self.view.frame.origin.y -= 40
                emojiClicked = true
            }
            return
        }
        
        
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.CGRectValue() {
            self.view.frame.origin.y += keyboardSize.height
            keyboardVisible = false
        }
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
            str = "Please connect to a network and the comments will load automatically."
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
        
        DataService.ds.REF_COMMENTS.childByAppendingPath(commentToRemove.commentKey).removeValueWithCompletionBlock { (error, ref) in
            
            if error != nil {
                print("Remove failed")
                EZLoadingActivity.showWithDelay("Failure", disableUI: true, seconds: 1.0)
                EZLoadingActivity.Settings.SuccessText = "Failure"
                EZLoadingActivity.hide(success: false, animated: true)
            } else {
                EZLoadingActivity.showWithDelay("Removed", disableUI: true, seconds: 1.0)
                EZLoadingActivity.Settings.SuccessText = "Removed"
                EZLoadingActivity.hide(success: true, animated: true)
                print("Remove")
                
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
        
        let reportCommentRef = DataService.ds.REF_REPORTED_COMMENTS.childByAppendingPath(self.reportedComment.commentKey)
        
        // Like observer
        reportCommentRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
            
            // If no report exist, create one
            if (snapshot.value as? NSNull) != nil {
                
                let comment: Dictionary<String, AnyObject> = [
                    "comment" : self.reportedComment.commentKey!,
                    "report_time" : Timestamp,
                    "report_count" : 1,
                ]
                
                reportCommentRef.setValue(comment)
                reportCommentRef.childByAppendingPath("reports_from_users").childByAppendingPath(currentUserKey()).setValue(Timestamp)
                
            } else {
                
                reportCommentRef.childByAppendingPath("reports_from_users").childByAppendingPath(currentUserKey()).setValue(Timestamp)
                
                // Should be put on server side
                if let snapshot = snapshot.children.allObjects as? [FDataSnapshot] {
                    for snap in snapshot {
                        if let commentDict = snap.value as? Dictionary<String, AnyObject> {
                            if commentDict[currentUserKey()] == nil {
                                let reportCount = commentDict.count + 1
                                reportCommentRef.childByAppendingPath("report_count").setValue(reportCount)
                            }
                        }
                    }
                }
            }
        })
    }
    
    @IBAction func commentBtnTapped(sender: AnyObject) {
        
        if !userProfileAdded() {
            JSSAlertView().danger(self, title: "Update Your Profile", text: "Please add a profile image and username before commenting.")
            return;
        }
        
        if commentTextView.text != "" && commentTextView.text != placeHolderText {
            dismissKeyboard()
            addComment(commentTextView.text)
            commentTextView.text = placeHolderText
            commentTextView.textColor = UIColor.lightGrayColor()
            tableView.reloadData()
        }
    }
}
