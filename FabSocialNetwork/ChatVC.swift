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
import Async

class ChatVC: JSQMessagesViewController, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    var otherUsername = ""
    var otherUserKey = ""
    
    // MARK: Properties
    var messages = [JSQMessage]()
    var userIsTypingRef: Firebase!
    var usersTypingQuery: FQuery!
    private var localTyping = false
    private var shownMessages = 25
    
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
        
        title = otherUsername.uppercaseString
        
        self.collectionView.emptyDataSetSource = self
        self.collectionView.emptyDataSetDelegate = self
        
        self.collectionView.backgroundColor = UIColor(red: CGFloat(18/255.0), green: CGFloat(18/255.0), blue: CGFloat(18/255.0), alpha: CGFloat(1.0))
        self.inputToolbar.contentView.backgroundColor = UIColor(red: CGFloat(30/255.0), green: CGFloat(30/255.0), blue: CGFloat(30/255.0), alpha: CGFloat(1.0))
        
        self.inputToolbar.contentView.textView.keyboardAppearance = .Dark
        self.inputToolbar.contentView.rightBarButtonItem.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        let rightBarbuttonHighlightedColor = UIColor(red: CGFloat(37/255.0), green: CGFloat(193/255.0), blue: CGFloat(81/255.0), alpha: CGFloat(0.88))
        self.inputToolbar.contentView.rightBarButtonItem.setTitleColor(rightBarbuttonHighlightedColor, forState: .Highlighted)
        self.inputToolbar.contentView.leftBarButtonItem = nil
        
        self.collectionView.loadEarlierMessagesHeaderTextColor = UIColor.lightTextColor()
        self.automaticallyScrollsToMostRecentMessage = false
        
        // No avatars
        collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSizeZero
        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero

    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        observeMessages()
        observeTyping()
        
        self.showLoadEarlierMessagesHeader = true
        
//        Async.main(after: 1.0) {
//            if self.messages.count == 0 {
//                self.showLoadEarlierMessagesHeader = false
//            } else {
//                self.showLoadEarlierMessagesHeader = true
//            }
//        }
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
        }
        
        return cell
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
    
    
    private func observeMessages() {

        let messagesQuery = DataService.ds.REF_MESSAGES.queryLimitedToLast(UInt(shownMessages))
        
        messagesQuery.observeEventType(.ChildAdded) { (snapshot: FDataSnapshot!) in
            
            let senderId = snapshot.value["senderId"] as! String
            let receiverId = snapshot.value["receiverId"] as! String
            var text = ""
            
            if let txt = snapshot.value["text"] as? String {
                text = txt
            }
            
            if (self.otherUserKey == senderId && currentUserKey() == receiverId) || (self.otherUserKey == receiverId && currentUserKey() == senderId) {
                
                self.addTextMessage(senderId, text: text)
                self.finishReceivingMessage()
            }
        }
    }
    
    private func observeTyping() {
        let typingIndicatorRef = DataService.ds.REF_BASE.childByAppendingPath("typingIndicator")
        userIsTypingRef = typingIndicatorRef.childByAppendingPath(senderId)
        userIsTypingRef.onDisconnectRemoveValue()
        usersTypingQuery = typingIndicatorRef.queryOrderedByValue().queryEqualToValue(true)
        
        usersTypingQuery.observeEventType(.Value) { (data: FDataSnapshot!) in
            
            // You're the only typing, don't show the indicator
            if data.childrenCount == 1 && self.isTyping {
                return
            }
            
            // Are there others typing?
            self.showTypingIndicator = data.childrenCount > 0
            self.scrollToBottomAnimated(true)
        }
        
    }
    
    func addTextMessage(id: String, text: String) {

        let message = JSQMessage(senderId: id, senderDisplayName: "Janne", date: NSDate(), text: text)
        messages.append(message)
    }
    
    override func textViewDidChange(textView: UITextView) {
        super.textViewDidChange(textView)
        // If the text is not empty, the user is typing
        isTyping = textView.text != ""
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, header headerView: JSQMessagesLoadEarlierHeaderView!, didTapLoadEarlierMessagesButton sender: UIButton!) {
        
        messages = [JSQMessage]()
        shownMessages += 25
        observeMessages()
    }
    
    
    func scrollToTop() {
        self.collectionView.contentOffset = CGPointMake(0, 0 - self.collectionView.contentOffset.y)
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
        
    }
    
    private func setupBubbles() {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        outgoingBubbleImageView = bubbleImageFactory.outgoingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleGreenColor())
        incomingBubbleImageView = bubbleImageFactory.incomingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleLightGrayColor())
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
