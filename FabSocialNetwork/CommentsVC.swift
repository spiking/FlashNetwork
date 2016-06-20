//
//  CommentsVC.swift
//  FabSocialNetwork
//
//  Created by Adam Thuvesen on 2016-06-09.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import UIKit
import Firebase
import SCLAlertView

class CommentsVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate {
    
    @IBOutlet weak var commentView: UIView!
    @IBOutlet weak var commentViewHeight: NSLayoutConstraint!
    
    var post: Post!
    var comments = [Comment]()
    var placeHolderText = "Leave a comment"
    
    @IBOutlet weak var stackViewHeight: NSLayoutConstraint!
    @IBOutlet weak var commentTextView: UITextView!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        tableView.delegate = self
        tableView.dataSource = self
        
        self.tableView.estimatedRowHeight = 80;
        self.tableView.rowHeight = UITableViewAutomaticDimension;
        
        self.edgesForExtendedLayout = UIRectEdge.None
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(CommentsVC.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        // Be able to push view up/down when keyboard is shown
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CommentsVC.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CommentsVC.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
        
        commentTextView.delegate = self
        
        print("Loaded post with key: \(post.postKey)")
        
        self.title = "COMMENTS"
        
        initObservers()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        
        if commentTextView.text == "" {
            commentTextView.text = placeHolderText
            commentTextView.textColor = UIColor.lightGrayColor()
        } else {
            commentTextView.textColor = UIColor.blackColor()
        }
    }
    
    func initObservers() {
        
        // Observe changes in Firebase, update instantly (code in closure)
        DataService.ds.REF_COMMENTS.observeEventType(.Value, withBlock: { snapshot in
            self.comments = []
            
            if let snapshot = snapshot.children.allObjects as? [FDataSnapshot] {
                for snap in snapshot {
                    if "\(snap.value.objectForKey("post")!)" == self.post.postKey {
                        if let commentDict = snap.value as? Dictionary<String, AnyObject> {
                            let key = snap.key
                            let comment = Comment(commentKey: key, dictionary: commentDict)
                            self.comments.append(comment)
                        }
                    }
                }
            }
            
            self.tableView.reloadData()
        })
        
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
            
            return cell
        } else {
            return CommentCell()
        }
        
    }
    
    func textViewShouldBeginEditing(textView: UITextView) -> Bool {
        commentTextView.textColor = UIColor.blackColor()
        
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
        
        view.removeConstraint(commentViewHeight)
    }
    
    func textViewDidBeginEditing(textView: UITextView) {
        commentViewHeight = NSLayoutConstraint(item: commentView, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: 100)
        view.addConstraint(commentViewHeight)
        
    }
    
    func addComment(comment: String!) {
        
        let currentUserKey = NSUserDefaults.standardUserDefaults().valueForKey(KEY_UID) as! String!
        let currentPostKey = post.postKey
        let comment : Dictionary<String, String> = ["user" : currentUserKey!, "post": currentPostKey, "comment" : comment!]
        
        DataService.ds.REF_COMMENTS.childByAutoId().setValue(comment)
    }
    
    @IBAction func commentBtnTapped(sender: AnyObject) {
        
        print("Post!")
        
        if commentTextView.text != "" && commentTextView.text != placeHolderText {
            dismissKeyboard()
            addComment(commentTextView.text)
            commentTextView.text = placeHolderText
            commentTextView.textColor = UIColor.lightGrayColor()
            print("Post comment!")
        } else {
            print("Nothing written")
        }
    }
    
    // Dismiss keyboard on tap gesture
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // Move view up
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
            self.view.frame.origin.y -= keyboardSize.height
        }
    }
    
    // Move view down
    func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
            self.view.frame.origin.y += keyboardSize.height
        }
    }
}
