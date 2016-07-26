//
//  ChatVC.swift
//  FabSocialNetwork
//
//  Created by Adam Thuvesen on 2016-07-12.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//


import UIKit
import Firebase
import JSQMessagesViewController
import Alamofire
import JSSAlertView
import Async

class ChatVC: JSQMessagesViewController, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    var otherUsername = ""
    var otherUserKey = ""
    
    private var messages = [JSQMessage]()
    private var userIsTypingRef: FIRDatabaseReference!
    private var usersTypingQuery: FIRDatabaseQuery!
    private var localTyping = false
    private var shownMessages = 100
    
    var isTyping: Bool {
        get {
            return localTyping
        }
        set {
            localTyping = newValue
            userIsTypingRef.setValue(newValue)
        }
    }
    
    var outgoingBubbleImageView: JSQMessagesBubbleImage!
    var incomingBubbleImageView: JSQMessagesBubbleImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupBubbles()
        loadOtherUsername()
        
        collectionView.emptyDataSetSource = self
        collectionView.emptyDataSetDelegate = self
        
        collectionView.backgroundColor = UIColor(red: CGFloat(18/255.0), green: CGFloat(18/255.0), blue: CGFloat(18/255.0), alpha: CGFloat(1.0))
        inputToolbar.contentView.backgroundColor = UIColor(red: CGFloat(30/255.0), green: CGFloat(30/255.0), blue: CGFloat(30/255.0), alpha: CGFloat(1.0))
        
        inputToolbar.contentView.textView.keyboardAppearance = .Dark
        inputToolbar.contentView.rightBarButtonItem.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        let rightBarbuttonHighlightedColor = UIColor(red: CGFloat(37/255.0), green: CGFloat(193/255.0), blue: CGFloat(81/255.0), alpha: CGFloat(0.88))
        inputToolbar.contentView.rightBarButtonItem.setTitleColor(rightBarbuttonHighlightedColor, forState: .Highlighted)
        inputToolbar.contentView.leftBarButtonItem = nil
        inputToolbar.contentView.textView.font = UIFont(name: "Avenir-Medium", size: 16)!
        
        collectionView.loadEarlierMessagesHeaderTextColor = UIColor.lightTextColor()
        
        seutpBlockButton()
        
        // No avatars
        collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSizeZero
        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero
        
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        observeMessages()
        observeTyping()
        
        if UIApplication.sharedApplication().isIgnoringInteractionEvents() {
            UIApplication.sharedApplication().endIgnoringInteractionEvents()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.showLoadEarlierMessagesHeader = false
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        removeTyping()
    }
    
    func seutpBlockButton() {
        let button: UIButton = UIButton(type: UIButtonType.Custom)
        button.setImage(UIImage(named: "Report.png"), forState: UIControlState.Normal)
        button.addTarget(self, action: #selector(OtherUserProfileVC.blockUserAlert), forControlEvents: UIControlEvents.TouchUpInside)
        button.frame = CGRectMake(0, 0, 25, 25)
        let barButton = UIBarButtonItem(customView: button)
        self.navigationItem.rightBarButtonItem = barButton

    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item]
        if message.senderId == senderId {
            return outgoingBubbleImageView
        } else {
            return incomingBubbleImageView
        }
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as! JSQMessagesCollectionViewCell
        
        _ = messages[indexPath.item]
        
        if (cell.textView?.textColor) != nil {
            cell.textView.textColor = UIColor(red: CGFloat(15/255.0), green: CGFloat(15/255.0), blue: CGFloat(15/255.0), alpha: CGFloat(1.0))
//            cell.textView.font = UIFont(name: "Avenir-Medium", size: 16)!
        }
        
        return cell
    }
    
    func observeMessages() {
        
        let messagesQuery = DataService.ds.REF_MESSAGES.queryLimitedToLast(UInt(shownMessages))
        
        messagesQuery.observeEventType(.ChildAdded) { (snapshot: FIRDataSnapshot!) in
            
            let senderId = snapshot.value!["senderId"] as! String
            let receiverId = snapshot.value!["receiverId"] as! String
            let text = snapshot.value!["text"] as! String
            
            if (self.otherUserKey == senderId && currentUserKey() == receiverId) || (self.otherUserKey == receiverId && currentUserKey() == senderId) {
                self.addTextMessage(senderId, text: text)
                self.finishReceivingMessage()
            }
        }
    }
    
    func removeTyping() {
        let typingIndicatorRef = DataService.ds.REF_BASE.child("typingIndicator")
        userIsTypingRef = typingIndicatorRef.child(senderId)
        userIsTypingRef.removeValue()
    }
    
    func observeTyping() {
        let typingIndicatorRef = DataService.ds.REF_BASE.child("typingIndicator")
        userIsTypingRef = typingIndicatorRef.child(senderId)
        userIsTypingRef.onDisconnectRemoveValue()
        usersTypingQuery = typingIndicatorRef.queryOrderedByValue().queryEqualToValue(true)
        
        usersTypingQuery.observeEventType(.Value) { (data: FIRDataSnapshot!) in
            
            // You are the only typing, dont show the indicator
            if data.childrenCount == 1 && self.isTyping {
                return
            }
            
            // Are there others typing?
            self.showTypingIndicator = data.childrenCount > 0
            self.scrollToBottomAnimated(true)
        }
        
    }
    
    func addTextMessage(id: String, text: String) {
        let message = JSQMessage(senderId: id, senderDisplayName: "", date: NSDate(), text: text)
        messages.append(message)
    }
    
    func loadOtherUsername() {
        DataService.ds.REF_USERS.child(otherUserKey).observeSingleEventOfType(.Value) { (snapshot: FIRDataSnapshot!) in
        
            if let username = snapshot.childSnapshotForPath("username").value as? String {
                self.otherUsername = username.uppercaseString
                self.title = self.otherUsername
            }
        }
    }
    
    override func textViewDidChange(textView: UITextView) {
        super.textViewDidChange(textView)
        // If the text is not empty, the user is typing
        isTyping = textView.text != ""
    }
    
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId receiverId: String!, senderDisplayName: String!, date: NSDate!) {
        
        let itemRef = DataService.ds.REF_MESSAGES.childByAutoId()
        let messageItem = [
            "text": text,
            "senderId": senderId,
            "receiverId": otherUserKey,
            "date": "\(date)"
        ]
        
        itemRef.setValue(messageItem)
        
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        
        finishSendingMessage()
        isTyping = false
        
        sendPushNotificationToUser()
        
        Async.main(after: 0.5) {
            if !isConnectedToNetwork() {
                JSSAlertView().danger(self, title: "No Internet Connection", text: "Your message will be sent when connected to a network.")
            }
        }
    }
    
    func sendPushNotificationToUser() {
        DataService.ds.REF_USERS.child(self.otherUserKey).observeSingleEventOfType(.Value) { (snapshot: FIRDataSnapshot!) in
            if let userPushId = snapshot.childSnapshotForPath("userPushId").value as? String {
                if self.otherUserKey != currentUserKey() {
                    print("\(getCurrentUsername().capitalizedString) sent you a message.")
                    oneSignal.postNotification(["contents": ["en":"\(getCurrentUsername().capitalizedString) sent you a message."], "include_player_ids": [userPushId]])
                }
            }
        }
    }
    
    func setupBubbles() {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        outgoingBubbleImageView = bubbleImageFactory.outgoingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleGreenColor())
        incomingBubbleImageView = bubbleImageFactory.incomingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleLightGrayColor())
    }
    
    func blockUserAlert() {
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()
        let alertview = JSSAlertView().show(self, title: "Block User", text: "Do you want to block \(otherUsername)? You will not be able to see any acitivty from this user, and vice versa. This cannot be undone. \n", buttonText: "Yes", cancelButtonText: "No", color: UIColorFromHex(0xe64c3c, alpha: 1))
        alertview.setTextTheme(.Light)
        alertview.addAction(blockUserAnswerYes)
        alertview.addCancelAction(blockUserAnswerNo)
        
        Async.background(after: 0.5) {
            if UIApplication.sharedApplication().isIgnoringInteractionEvents() {
                UIApplication.sharedApplication().endIgnoringInteractionEvents()
            }
        }
    }
    
    func blockUserAnswerYes() {
        blockUser()
    }
    
    func blockUserAnswerNo() {
        // Do nothing
    }
    
    func blockUser() {
        DataService.ds.REF_USER_CURRENT.child("blocked_users").child(otherUserKey).setValue("TRUE")
        DataService.ds.REF_USERS.child(otherUserKey).child("blocked_users").child(currentUserKey()).setValue("TRUE")
        DataService.ds.REF_USER_CURRENT.child("favorites").child(otherUserKey).removeValue()
        DataService.ds.REF_USERS.child(otherUserKey).child("favorites").child(currentUserKey()).removeValue()
        
        NSNotificationCenter.defaultCenter().postNotificationName("update", object: nil)
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
            str = "It looks like there are no messages.\n If you like, send one below."
        } else {
            str = "Please connect to a network.\n The messages will load automatically."
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
