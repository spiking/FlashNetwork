//
//  FeedVC.swift
//  FabSocialNetwork
//
//  Created by Adam Thuvesen on 2016-06-05.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import UIKit
import Foundation
import Firebase
import Alamofire
import MobileCoreServices
import EZLoadingActivity
import JSSAlertView
import BTNavigationDropdownMenu
import Async

class FeedVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    var posts = [Post]()
    static var imageCache = NSCache() // Static since single instance (global)
    var imagePicker: UIImagePickerController!
    var imageSelected = false
    var loadingData = false
    var alert = false
    var noConnectionAlerts = 0
    var typeOfLogin = ""
    var placeHolderText = "Anything you would like to share?"
    var refreshControl: UIRefreshControl!
    var previousOffset = CGFloat(0)
    var postsShown = 20
    var reportPost: Post!
    var keyboardHeight: CGFloat = 0.0
    var rows: CGFloat = 0.0
    var feedMode = FeedMode.Popular
    var menuView: BTNavigationDropdownMenu!
    var timer: NSTimer?
    var spinner = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
    var previousRect = CGRectZero
    var heightConstraint: NSLayoutConstraint?
    var blockedUsers = [String]()
    
    var cancelButton: UIButton!
    
    enum FeedMode {
        case Popular
        case Hottest
        case Latest
    }
    
    @IBOutlet weak var postViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var postView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var postTextView: UITextView!
    @IBOutlet weak var imageSelector: UIImageView!
    @IBOutlet weak var postBottomConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        tableView.tableFooterView = UIView()
        tableView.allowsSelection = true
        
        tableView.estimatedRowHeight = 550
        tableView.rowHeight = UITableViewAutomaticDimension
        
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(FeedVC.refresh(_:)), forControlEvents: UIControlEvents.ValueChanged)
        tableView.addSubview(refreshControl)
        
        spinner.hidesWhenStopped = true
        spinner.color = UIColor.grayColor()
        spinner.frame = CGRectMake(0, 0, 320, 44);
        tableView.tableFooterView = spinner;
        
        postTextView.delegate = self
        
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.navigationBar.tintColor = UIColor.blackColor()
        imagePicker.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.blackColor()]
        
        let tap : UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(FeedVC.dismisskeyboard))
        view.addGestureRecognizer(tap)
        
        setupProfileButton()
        setupCancelButton()
        setupSortMenu()
        
        title = "FAB NETWORK"
        navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Plain, target:nil, action:nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(FeedVC.updateData(_:)), name:"update", object: nil)
        
        // Be able to push view up/down when keyboard is shown, observers
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CommentsVC.keyboardWillShow(_:)), name:UIKeyboardWillShowNotification, object: nil);
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CommentsVC.keyboardWillHide(_:)), name:UIKeyboardWillHideNotification, object: nil);
        
        if firstLogin {
            EZLoadingActivity.hide()
        }
        
        if isConnectedToNetwork() {
            EZLoadingActivity.show("Loading...", disableUI: false)
        }
        
        
        loadBlockedUsersAndInitalDataFromFirebase()
        loadProfileData()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        
        if postTextView.text == "" || postTextView.text == placeHolderText {
            postTextView.text = placeHolderText
            postTextView.textColor = UIColor.lightGrayColor()
        } else {
            postTextView.textColor = UIColor.whiteColor()
        }
    }
    
    func setupCancelButton() {
        
        cancelButton = UIButton(type: UIButtonType.Custom)
        cancelButton.setImage(UIImage(named: "Cancel.png"), forState: UIControlState.Normal)
        cancelButton.addTarget(self, action: #selector(FeedVC.cancelBtnPressed), forControlEvents: UIControlEvents.TouchUpInside)
        cancelButton.frame = CGRectMake(0, 0, 53, 20)
        let barButton = UIBarButtonItem(customView: cancelButton)
        self.navigationItem.leftBarButtonItem = barButton
        hideCancelButton()
    }
    
    func setupProfileButton() {
        let button: UIButton = UIButton(type: UIButtonType.Custom)
        button.setImage(UIImage(named: "profile2.png"), forState: UIControlState.Normal)
        button.addTarget(self, action: #selector(FeedVC.profileBtnPressed), forControlEvents: UIControlEvents.TouchUpInside)
        button.frame = CGRectMake(0, 0, 32, 32)
        let barButton = UIBarButtonItem(customView: button)
        self.navigationItem.rightBarButtonItem = barButton
    }
    
    func setupSortMenu() {
        let items = ["MOST POPULAR", "HOTTEST", "LATEST"]
        menuView = BTNavigationDropdownMenu(navigationController: self.navigationController, title: items.first!, items: items)
        menuView.cellTextLabelColor = UIColor.lightTextColor()
        menuView.cellTextLabelFont = UIFont(name: "Avenir", size: 14)
        menuView.menuTitleColor = UIColor.whiteColor()
        menuView.cellSelectionColor = UIColor.darkGrayColor()
        
        self.navigationItem.titleView = menuView
        
        menuView.didSelectItemAtIndexHandler = {[weak self] (indexPath: Int) -> () in
            switch indexPath {
            case 0:
                self!.feedMode = .Popular
                self!.loadDataFromFirebase()
            case 1:
                self!.feedMode = .Hottest
                self!.loadDataFromFirebase()
            case 2:
                self!.feedMode = .Latest
                self!.loadDataFromFirebase()
            default:
                break
            }
        }
    }
    
    func loadDataFromFirebase() {
        
        if !isConnectedToNetwork() {
            JSSAlertView().danger(self, title: "No Internet Connection", text: "Please connect to a network and the feed will load automatically.")
        }
        
        switch feedMode {
        case .Popular:
            loadMostPopularFromFirebase()
        case .Hottest:
            loadHottestFromFirebase()
        case .Latest:
            loadLatestFromFirebase()
        }
        
        scrollToTop()
        postsShown = 20
    }
    
    func loadBlockedUsersAndInitalDataFromFirebase() {
        DataService.ds.REF_USER_CURRENT.childByAppendingPath("blocked_users").observeEventType(.Value, withBlock: { snapshot in
        
            if let snapshot = snapshot.children.allObjects as? [FDataSnapshot] {
                for snap in snapshot {
                    self.blockedUsers.append(snap.key)
                }
            }
            
            switch self.feedMode {
            case .Popular:
                self.loadMostPopularFromFirebase()
            case .Hottest:
                self.loadHottestFromFirebase()
            case .Latest:
                self.loadLatestFromFirebase()
            }
        })
    }
    
    func loadHottestFromFirebase() {
        
        let count = posts.count
        let lastTwoDays = Double(Timestamp)! - (86000.0 * 2)
        let lastTwoDaysStr = "\(lastTwoDays)"
        
        // Observe changes in Firebase
        DataService.ds.REF_POSTS.queryLimitedToLast(UInt(postsShown)).queryOrderedByChild("timestamp").queryStartingAtValue(lastTwoDaysStr, childKey: "timestamp").observeSingleEventOfType(.Value, withBlock: { snapshot in
            self.posts = []
            
            if let snapshot = snapshot.children.allObjects as? [FDataSnapshot] {
                for snap in snapshot {
                    if let postDict = snap.value as? Dictionary<String, AnyObject> {
                        let key = snap.key
                        let post = Post(postKey: key, dictionary: postDict)
                        
                        if !self.blockedUsers.contains(post.userKey) {
                            self.posts.append(post)
                        }
                    }
                }
            }
            
            if count == 0 {
                EZLoadingActivity.hide()
            }
            
            if firstLogin {
                self.loginMessage()
                firstLogin = false
            }
            
            // Sort hottest, most likes in the last 48 h
            self.posts.sortInPlace({ $0.likes > $1.likes })
            self.tableView.reloadData()
        })
        
    }
    
    func loadMostPopularFromFirebase() {
        
        let count = posts.count
        
        // Observe changes in Firebase
        DataService.ds.REF_POSTS.queryLimitedToLast(UInt(postsShown)).queryOrderedByChild("likes").observeSingleEventOfType(.Value, withBlock: { snapshot in
            self.posts = []
            
            if let snapshot = snapshot.children.allObjects as? [FDataSnapshot] {
                for snap in snapshot {
                    
                    if let postDict = snap.value as? Dictionary<String, AnyObject> {
                        let key = snap.key
                        let post = Post(postKey: key, dictionary: postDict)
                        
                        if !self.blockedUsers.contains(post.userKey) {
                            self.posts.append(post)
                        }
                    }
                }
            }
            
            if count == 0 {
                EZLoadingActivity.hide()
            }
            
            if firstLogin {
                self.loginMessage()
                firstLogin = false
            }
            
            self.posts = self.posts.reverse()
            self.tableView.reloadData()
            
        })
    }
    
    func loadLatestFromFirebase() {
        
        let count = posts.count
        
        // Observe changes in Firebase
        DataService.ds.REF_POSTS.queryLimitedToLast(UInt(postsShown)).observeSingleEventOfType(.Value, withBlock: { snapshot in
            self.posts = []
            
            if let snapshot = snapshot.children.allObjects as? [FDataSnapshot] {
                for snap in snapshot {
                    if let postDict = snap.value as? Dictionary<String, AnyObject> {
                        let key = snap.key
                        let post = Post(postKey: key, dictionary: postDict)
                        
                        if !self.blockedUsers.contains(post.userKey) {
                            self.posts.append(post)
                        }
                    }
                }
            }
            
            if count == 0 {
                EZLoadingActivity.hide()
            }
            
            if firstLogin {
                self.loginMessage()
                firstLogin = false
            }
            
            self.posts = self.posts.reverse()
            self.tableView.reloadData()
        })
        
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        // Loads 20 posts each refresh
        if posts.count % 20 != 0 {
            spinner.stopAnimating()
            return
        }
        
        if !loadingData && indexPath.row == postsShown - 1 {
            spinner.startAnimating()
            startTimerForRefresh()
        }
    }
    
    func startTimerForRefresh() {
        timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(FeedVC.tryToRefresh), userInfo: nil, repeats: true)
    }
    
    func stopTimerForRefresh() {
        timer?.invalidate()
    }
    
    func tryToRefresh() {
        if isConnectedToNetwork() {
            loadingData = true
            alert = false
            stopTimerForRefresh()
            refreshMore()
        } else {
            if !alert {
                JSSAlertView().danger(self, title: "No Internet Connection", text: "Please connect to a network and the feed will load automatically.")
                alert = true
            }
        }
    }
    
    func refreshMore() {
        
        Async.background() {
            
            // This runs on the background queue
            
            self.postsShown += 20
            
            switch self.feedMode {
            case .Popular:
                self.loadMostPopularFromFirebase()
            case .Hottest:
                self.loadHottestFromFirebase()
            case .Latest:
                self.loadLatestFromFirebase()
            }
            
            }.main() {
                // This runs on the main queue
                
                self.tableView.reloadData()
                self.loadingData = false
        }
    }
    
    // Animate push of post view when user starts scrolling
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        if postTextView.isFirstResponder() {
            return
        }
        
        dismisskeyboard()
        stopLikeAnimation()
        
        // If we reach bottom
        if (self.tableView.contentOffset.y >= (self.tableView.contentSize.height - self.tableView.bounds.size.height)) {
            return
        }
        
        let height = scrollView.frame.size.height // Screen height
        var currentOffset = scrollView.contentOffset.y // Above screen
        let distanceToBottom = scrollView.contentSize.height - previousOffset // Below screen
        
        // Scroll down
        if previousOffset < currentOffset && distanceToBottom > height {
            
            // Is postview visible
            if !isVisible(postView) {
                return
            }
            
            if currentOffset > height {
                currentOffset = height
            }
            
            self.postViewTopConstraint.constant += previousOffset - currentOffset
            previousOffset = currentOffset
            
            // Scroll up
        } else {
            if currentOffset < 0 {
                currentOffset = 0
            }
            self.postViewTopConstraint.constant += previousOffset - currentOffset
            previousOffset = currentOffset
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if let cell = tableView.dequeueReusableCellWithIdentifier("PostCell") as? PostCell {
            
            // Cancel request if user scrolls
            cell.request?.cancel()
            let post = posts[indexPath.row]
            var img: UIImage?
            
            // Load post image from local cache
            if let url = post.imageUrl {
                img = FeedVC.imageCache.objectForKey(url) as? UIImage
            }
            
            cell.configureCell(post, img: img)
            
            // Push comment segue which will be executed when tapped
            cell.commentTapAction = { (cell) in
                self.performSegueWithIdentifier(SEGUE_COMMENTSVC, sender: post)
            }
            
            cell.reportTapAction = { (cell) in
                self.reportPost = post
                self.reportAlert()
            }
            
            cell.blockUserTapAction = { (cell) in
                self.performSegueWithIdentifier(SEGUE_OTHERUSERPROFILEVC, sender: post.userKey)
            }
            
            cell.layoutIfNeeded()
            
            return cell
            
        } else {
            return PostCell()
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let post = posts[indexPath.row]
        
        if post.imageUrl == nil || post.imageUrl == "" {
            // Not pretty, but should work
            return 115 + heightForView(post.postDescription, width: screenWidth - 51)
        } else {
            return tableView.estimatedRowHeight + heightForView(post.postDescription, width: screenWidth - 24)
        }
    }
    
    func refresh(sender:AnyObject) {
        
        if isConnectedToNetwork() {
            loadDataFromFirebase()
            tableView.reloadData()
            refreshControl.endRefreshing()
        } else {
            refreshControl.endRefreshing()
            JSSAlertView().danger(self, title: "No Internet Connection", text: "Please connect to a network and the feed will load automatically.")
        }
    }
    
    func updateData(notification: NSNotification){
        loadDataFromFirebase()
    }
    
    func cancelBtnPressed() {
        dismisskeyboard()
        hideCancelButton()
        cancelAlert()
    }
    
    func cancelAlert() {
        
        // dismisskeyboard()
        
        if (postTextView.text != "" && postTextView.text != placeHolderText) || imageSelected {
            let alertview = JSSAlertView().show(self, title: "Save Draft", text: "Do you want to save this post as a draft?", buttonText: "Yes", cancelButtonText: "No", color: UIColorFromHex(0xe64c3c, alpha: 1))
            alertview.setTextTheme(.Light)
            alertview.addAction(cancelAnswerYes)
            alertview.addCancelAction(cancelAnswerNo)
        }
    }
    
    func cancelAnswerYes() {
        
    }
    
    func cancelAnswerNo() {
        postTextView.text = placeHolderText
        imageSelector.image = UIImage(named: "Camera2")
        imageSelected = false
    }
    
    func showCancelButton() {
        cancelButton.hidden = false
    }
    
    func hideCancelButton() {
        cancelButton.hidden = true
    }
    
    func profileBtnPressed() {
        
        self.dismisskeyboard()
        self.menuView.hide()
        
        // Short delay
        func delay(delay:Double, closure:()->()) {
            dispatch_after(
                dispatch_time(
                    DISPATCH_TIME_NOW,
                    Int64(delay * Double(NSEC_PER_SEC))
                ),
                dispatch_get_main_queue(), closure)
        }
        delay(0.3) {
            self.performSegueWithIdentifier(SEGUE_PROFILEVC, sender: nil)
        }
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        imagePicker.dismissViewControllerAnimated(true, completion: nil)
        imageSelector.image = image
        imageSelected = true
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        imagePicker.dismissViewControllerAnimated(true, completion: nil)
        imageSelector.image = UIImage(named: "Camera2")
        imageSelected = false
    }
    
    func keyboardWillShow(sender: NSNotification) {
        
        showCancelButton()
        
        if let constraint = heightConstraint {
            view.removeConstraint(constraint)
        }
        
        var info = sender.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        
        UIView.animateWithDuration(0.1, animations: { () -> Void in
            self.postTextView.scrollEnabled = true
            self.postBottomConstraint.constant = keyboardFrame.size.height
        })
    }
    
    func keyboardWillHide(sender: NSNotification) {
        hideCancelButton()
        
        self.postTextView.scrollEnabled = false
        self.postBottomConstraint.constant =  0
        
        heightConstraint = NSLayoutConstraint(item: postTextView, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: 40)
        view.addConstraint(heightConstraint!)
    }
    
    func dismisskeyboard() {
        view.endEditing(true)
    }
    
    func scrollToTop() {
        self.tableView.contentOffset = CGPointMake(0, 0 - self.tableView.contentInset.top);
    }
    
    func textViewShouldBeginEditing(textView: UITextView) -> Bool {
        
        postTextView.textColor = UIColor.whiteColor()
        
        if postTextView.text == placeHolderText {
            postTextView.text = ""
        }
        
        return true
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        
        if postTextView.text == "" {
            postTextView.text = placeHolderText
            postTextView.textColor = UIColor.lightGrayColor()
        }
    }
    
    func loginMessage() {
        
        switch typeOfLogin {
        case "OLD_ACCOUNT":
            successAlertFeedVC(self, title: "Welcome back", msg: "You have successfully been logged in!")
            EZLoadingActivity.hide()
        case "NEW_ACCOUNT":
            successAlertFeedVC(self, title: "Welcome", msg: "A new account has successfully been created! Before you start posting, you should add a username and a profile image. To do so, click the profile icon in the upper right corner.")
            EZLoadingActivity.hide()
        default: break
            // Do nothing
        }
    }
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        var str = ""
        if isConnectedToNetwork() {
            str = "No Posts"
        } else {
            str = "No Internet Connection"
        }
        
        let attrs = [NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)]
        return NSAttributedString(string: str, attributes: attrs)
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        var str = ""
        if isConnectedToNetwork() {
            str = "It looks like there are no posts. If you like, add one above."
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
    
    func updateScores(hasImage: Bool) {
        DataService.ds.REF_USER_CURRENT.childByAppendingPath("score").observeSingleEventOfType(.Value, withBlock: { snapshot in
            
            if var score = snapshot.value as? Int {
                
                let diceRoll = Int(arc4random_uniform(10) + 1)
                
                if hasImage {
                    score += 10 + diceRoll
                } else {
                    score += 5 + diceRoll
                }
                
                DataService.ds.REF_USER_CURRENT.childByAppendingPath("score").setValue(score)
            }
            
        })
    }
    
    func postToFireBase(imgUrl: String?) {
        
        var post: Dictionary<String, AnyObject> = [
            "description": postTextView.text!,
            "likes": 0,
            "user" : currentUserKey(),
            "timestamp" : Timestamp
        ]
        
        var image = false
        
        if imgUrl != nil {
            post["imageUrl"] = imgUrl!
            image = true
        } else {
            post["imageUrl"] = ""
        }
        
        // Add post to firebase
        let firebasePost = DataService.ds.REF_POSTS.childByAutoId()
        firebasePost.setValue(post)
        imageSelected = false
        
        postTextView.text = placeHolderText
        postTextView.textColor = UIColor.lightGrayColor()
        imageSelector.image = UIImage(named: "Camera2")
        
        updateScores(image)
        
        EZLoadingActivity.Settings.SuccessText = "Uploded"
        EZLoadingActivity.hide(success: true, animated: true)
        
        switch feedMode {
        case .Popular:
            loadMostPopularFromFirebase()
        case .Hottest:
            loadHottestFromFirebase()
        case .Latest:
            loadLatestFromFirebase()
        }
    }
    
    
    // If app has been reinstalled or user has logged out, must fetch user data from firebase
    
    func loadProfileData() {
        
        isUserAuthenticated(self)
        
        if !userProfileAdded() {
            
            DataService.ds.REF_USER_CURRENT.observeEventType(.Value, withBlock: { snapshot in
                
                if let snapshot = snapshot.children.allObjects as? [FDataSnapshot] {
                    for snap in snapshot {
                        if snap.key == "imgUrl" {
                            let profileUrl = snap.value
                            NSUserDefaults.standardUserDefaults().setValue(profileUrl, forKey: "profileUrl")
                        } else if snap.key == "username" {
                            let username = snap.value
                            NSUserDefaults.standardUserDefaults().setValue(username, forKey: "username")
                        } else if snap.key == "terms" {
                            let terms = snap.value
                            NSUserDefaults.standardUserDefaults().setValue(terms, forKey: "terms")
                        }
                        
                    }
                }
            })
        }
    }
    
    func reportAlert() {
        let alertview = JSSAlertView().show(self, title: "Report", text: "Do you want to report this post for containing objectionable content? \n", buttonText: "Yes", cancelButtonText: "No", color: UIColorFromHex(0xe64c3c, alpha: 1))
        alertview.setTextTheme(.Light)
        alertview.addAction(reportAnswerYes)
        alertview.addCancelAction(reportAnswerNo)
    }
    
    func reportAnswerYes() {
        reportUserPost()
    }
    
    func reportAnswerNo() {
        // Do nothing
    }
    
    func reportUserPost() {
        
        let reportPostRef = DataService.ds.REF_REPORTED_POSTS.childByAppendingPath(self.reportPost.postKey)
        
        // Like observer
        reportPostRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
            
            // If no report exist, create one
            if (snapshot.value as? NSNull) != nil {
                
                let post: Dictionary<String, AnyObject> = [
                    "post" : self.reportPost.postKey,
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
    
    func accessCamera() {
        imagePicker.sourceType = UIImagePickerControllerSourceType.Camera;
        imagePicker.allowsEditing = false
        self.presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    func accessLibrary() {
        imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        imagePicker.allowsEditing = true
        self.presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        dismisskeyboard()
        
        if segue.identifier == SEGUE_COMMENTSVC {
            if let commentsVC = segue.destinationViewController as? CommentsVC {
                if let post = sender as? Post {
                    commentsVC.post = post
                }
            }
        } else if segue.identifier == SEGUE_OTHERUSERPROFILEVC {
            if let commentsVC = segue.destinationViewController as? OtherUserProfileVC {
                if let userKey = sender as? String {
                    commentsVC.otherUserKey = userKey
                }
            }
        }
    }
    
    @IBAction func selectImage(sender: UITapGestureRecognizer) {
        
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera) {
            
            let alertview = JSSAlertView().show(self, title: "Access Photo Library Or Camera?", text: "", buttonText: "Library", cancelButtonText: "Camera", color: UIColorFromHex(0x25c051, alpha: 1))
            alertview.setTextTheme(.Light)
            alertview.addAction(accessLibrary)
            alertview.addCancelAction(accessCamera)
            
        } else {
            imagePicker.allowsEditing = true
            self.presentViewController(imagePicker, animated: true, completion: nil)
        }
    }
    
    @IBAction func makePost(sender: AnyObject) {
        
        dismisskeyboard()
        
        if !userProfileAdded() {
            JSSAlertView().danger(self, title: "Update Your Profile", text: "Please add a username and a profile image before posting. You can find the profile by clicking on the icon in the upper right corner.")
            return
        }
        
        if !isConnectedToNetwork() {
            JSSAlertView().danger(self, title: "No Internet Connection", text: "Please connect to a network and try again.")
            return
        }
        
        if let txt = postTextView.text where txt != "" && postTextView.text != placeHolderText {
            
            EZLoadingActivity.show("Uploading...", disableUI: false)
            
            if let img = imageSelector.image where imageSelected == true {
                
                let urlStr = "https://post.imageshack.us/upload_api.php"
                let url = NSURL(string: urlStr)!
                
                // Convert to JPG & compress 70 %
                let imgData = UIImageJPEGRepresentation(img, 0.3)!
                
                // Convert Imageshack API key to data format
                let keyData = "12DJKPSU5fc3afbd01b1630cc718cae3043220f3".dataUsingEncoding(NSUTF8StringEncoding)!
                
                // Convert JSON to data format
                let keyJson = "json".dataUsingEncoding(NSUTF8StringEncoding)!
                
                // Upload post image with ImageShack
                Alamofire.upload(.POST, url, multipartFormData: { MultipartFormData in
                    
                    MultipartFormData.appendBodyPart(data: keyData, name: "key")
                    MultipartFormData.appendBodyPart(data: imgData, name: "fileupload", fileName: "image", mimeType: "image/jpg")
                    MultipartFormData.appendBodyPart(data: keyJson, name: "format")
                    
                    }, encodingCompletion: { encodingResult in
                        switch encodingResult {
                            
                            
                            
                        case .Success(let upload, _, _):
                            upload.responseJSON(completionHandler: { response in
                                
                                if let info = response.result.value as? Dictionary<String,AnyObject> {
                                    if let links = info["links"] as? Dictionary<String,AnyObject> {
                                        if let imageLink = links["image_link"] as? String {
                                            self.postToFireBase(imageLink)
                                        }
                                        
                                    }
                                    
                                }
                                
                            })
                            
                        case.Failure(let error):
                            print(error)
                        }
                        
                })
                
            } else {
                self.postToFireBase(nil)
            }
            
        } else {
            JSSAlertView().danger(self, title: "No Description", text: "Please add a description before posting.")
        }
    }
}

