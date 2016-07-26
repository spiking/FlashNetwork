//
//  MessageVC.swift
//  FabSocialNetwork
//
//  Created by Adam Thuvesen on 2016-07-26.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import UIKit
import Firebase

class MessageVC: UIViewController, UITableViewDelegate, UITableViewDataSource, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    private var userMessages = [Message]()
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        
        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableViewAutomaticDimension
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Plain, target:nil, action:nil)
        
        title = "MESSAGES"
        
        loadMessagesFromUsersFirebase()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        loadMessagesFromUsersFirebase()
        
        if userMessages.count == 0 {
            tableView.tableFooterView = UIView()
        }
    }
    
    func loadMessagesFromUsersFirebase() {
        
        DataService.ds.REF_MESSAGES.observeSingleEventOfType(.Value, withBlock: { snapshot in
            
            self.userMessages = [Message]()
            
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                
                let reversedSnapshot = snapshot.reverse()
                
                for snap in reversedSnapshot {
                    if let receiverId = snap.childSnapshotForPath("receiverId").value as? String {
                        if let senderId = snap.childSnapshotForPath("senderId").value as? String {
                            if receiverId == currentUserKey() {
                                if let message = snap.childSnapshotForPath("text").value as? String {
                                    
                                    let userMessage = Message(senderId: senderId, receiverId: receiverId, lastMessage: message, lastMessageFromCurrentUser: false)
                                    
                                    if !self.userMessages.contains(userMessage) && !blockedUsers.contains(senderId) {
                                        self.userMessages.append(userMessage)
                                    }
                                    
                                }
                            } else if senderId == currentUserKey() {
                                if let message = snap.childSnapshotForPath("text").value as? String {
                                    
                                    let userMessage = Message(senderId: senderId, receiverId: receiverId, lastMessage: message, lastMessageFromCurrentUser: true)
                                    
                                    if !self.userMessages.contains(userMessage) && !blockedUsers.contains(receiverId) {
                                        self.userMessages.append(userMessage)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            self.tableView.reloadData()
            
        })
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let userMessage = userMessages[indexPath.row]
        let otherUserKey = userMessage.getOtherUserId
        self.performSegueWithIdentifier(SEGUE_CHATVC, sender: otherUserKey)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        switch segue.identifier {
        case SEGUE_OTHERUSERPROFILEVC?:
            if let otherUserProfileVC = segue.destinationViewController as? OtherUserProfileVC {
                if let otherUserKey = sender as? String {
                    otherUserProfileVC.otherUserKey = otherUserKey
                }
            }
        case SEGUE_CHATVC?:
            if let chatVC = segue.destinationViewController as? ChatVC {
                if let otherUserKey = sender as? String {
                    chatVC.otherUserKey = otherUserKey
                    chatVC.senderId = currentUserKey()
                    chatVC.senderDisplayName = ""
                }
            }
        default:
            break
        }
        
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userMessages.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if let cell = tableView.dequeueReusableCellWithIdentifier("MessageCell") as? MessageCell {
            
            // Cancel request if user scrolls
            cell.request?.cancel()
            let userMessage = userMessages[indexPath.row]
            
            cell.configureCell(userMessage)
            
            let backgroundView = UIView()
            backgroundView.backgroundColor = UIColor.blackColor()
            cell.selectedBackgroundView = backgroundView
            
            return cell
        } else {
            return MessageCell()
        }
    }
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        var str = ""
        if isConnectedToNetwork() {
            str = "No Messages"
        } else {
            str = "No Internet Connection"
        }
        
        let attrs = [NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)]
        return NSAttributedString(string: str, attributes: attrs)
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        var str = ""
        if isConnectedToNetwork() {
            str = "It looks like you have not received any messages."
        } else {
            str = "Please connect to a network. The users will load automatically."
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
    
}
