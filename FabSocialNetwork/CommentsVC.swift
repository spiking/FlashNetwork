//
//  CommentsVC.swift
//  FabSocialNetwork
//
//  Created by Adam Thuvesen on 2016-06-09.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import UIKit
import Firebase

class CommentsVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    var post: Post!
    var comments = [Comment]()
    
    @IBOutlet weak var commentTextField: UITextField!
    
    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        self.edgesForExtendedLayout = UIRectEdge.None
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(CommentsVC.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        // Be able to push view up/down when keyboard is shown
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CommentsVC.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CommentsVC.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
        
        commentTextField.delegate = self
        print("Loaded post with key: \(post.postKey)")
        
        initObservers()
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
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print("Selected row")
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
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == commentTextField && commentTextField.text != "" {
            commentTextField.resignFirstResponder()
            addComment(commentTextField.text!)
            commentTextField.text = ""
            return false
        }
        return true
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        
        if NSUserDefaults.standardUserDefaults().valueForKey("profileUrl") as! String! == nil {
            showAlert("Action not allowed!", msg: "Please choose a profile picture and username first!")
            commentTextField.text = ""
            commentTextField.resignFirstResponder()
        }
    }
    
    func addComment(comment: String!) {
        
        let currentUserKey = NSUserDefaults.standardUserDefaults().valueForKey(KEY_UID) as! String!
        let currentPostKey = post.postKey
        let comment : Dictionary<String, String> = ["user" : currentUserKey!, "post": currentPostKey, "comment" : comment!]
        
        DataService.ds.REF_COMMENTS.childByAutoId().setValue(comment)
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
    
    func showAlert(title: String, msg: String) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .Alert)
        let action = UIAlertAction(title: "Ok", style: .Default, handler: nil)
        alert.addAction(action)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    
}
