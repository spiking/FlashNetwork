//
//  FeedVC.swift
//  FabSocialNetwork
//
//  Created by Adam Thuvesen on 2016-06-05.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import UIKit
import Firebase
import Alamofire
import SCLAlertView
import MobileCoreServices
import EZLoadingActivity
import JSSAlertView
import BTNavigationDropdownMenu


class FeedVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    @IBOutlet weak var postViewTopConstraint: NSLayoutConstraint!
    
    var posts = [Post]()
    static var imageCache = NSCache() // Static since single instance (global)
    var imagePicker: UIImagePickerController!
    var imageSelected = false
    var noConnectionAlerts = 0
    var typeOfLogin = ""
    var placeHolderText = "Anything you would like to share?"
    var refreshControl: UIRefreshControl!
    var previousOffset = CGFloat(0)
    var firstLogin = true
    var loadingData = false
    var postsShown = 20
    var alert = false
    
    var sortedOn = "STANDARD"
    
    var menuView: BTNavigationDropdownMenu!
    
    var timer: NSTimer?
    var spinner = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
    
    @IBOutlet weak var postViewHeight: NSLayoutConstraint!
    @IBOutlet weak var postView: MaterialView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var postTextViewHeight: NSLayoutConstraint!
    @IBOutlet weak var postTextView: MaterialTextView!
    @IBOutlet weak var imageSelector: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        tableView.tableFooterView = UIView()
        tableView.allowsSelection = true
        
        
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(FeedVC.refresh(_:)), forControlEvents: UIControlEvents.ValueChanged)
        tableView.addSubview(refreshControl) // not required when using UITableViewController
        
        self.tableView.estimatedRowHeight = 500
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        postTextView.delegate = self
        
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.navigationBar.tintColor = UIColor.blackColor()
        imagePicker.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.blackColor()]
        
        
        let tap : UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(FeedVC.dismisskeyboard))
        view.addGestureRecognizer(tap)
        
        setupProfileButton()
        setupSortMenu()
        
        self.title = "FAB NETWORK"
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Plain, target:nil, action:nil)
        
        if isConnectedToNetwork() {
            print("Connected!")
            EZLoadingActivity.show("Loading...", disableUI: false)
        }
        
        loadProfileData()
        
        print("User logged in as \(typeOfLogin)")
        
        spinner.hidesWhenStopped = true
        spinner.color = UIColor.grayColor()
        spinner.frame = CGRectMake(0, 0, 320, 44);
        self.tableView.tableFooterView = spinner;
    
        loadStandardFromFirebase()
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
    
    func setupProfileButton() {
        let button: UIButton = UIButton(type: UIButtonType.Custom)
        button.setImage(UIImage(named: "profile2.png"), forState: UIControlState.Normal)
        button.addTarget(self, action: #selector(FeedVC.profileBtnPressed), forControlEvents: UIControlEvents.TouchUpInside)
        button.frame = CGRectMake(0, 0, 32, 32)
        let barButton = UIBarButtonItem(customView: button)
        self.navigationItem.rightBarButtonItem = barButton
    }
    
    func setupSortMenu() {
        let items = ["STANDARD", "MOST POPULAR", "LATEST"]
        menuView = BTNavigationDropdownMenu(navigationController: self.navigationController, title: items.first!, items: items)
        menuView.cellTextLabelColor = UIColor.lightTextColor()
        menuView.cellTextLabelFont = UIFont(name: "Avenir", size: 14)
        menuView.menuTitleColor = UIColor.whiteColor()
        menuView.cellSelectionColor = UIColor.darkGrayColor()
        
        self.navigationItem.titleView = menuView
        
        menuView.didSelectItemAtIndexHandler = {[weak self] (indexPath: Int) -> () in
            print("Did select item at index: \(indexPath)")
            switch indexPath {
            case 0:
                self!.loadHottestSelected()
            case 1:
                self!.loadMostPopularSelected()
            case 2:
                self!.loadLatestSelected()
            default:
                print("DEFAULT")
            }
        }
    }
    
    func scrollToTop() {
        tableView.setContentOffset(CGPointZero, animated:true)
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            let indexPath = NSIndexPath(forRow: 0, inSection: 0)
            self.tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Bottom, animated: true)
            
        })
    }
    
    func loadMostPopularSelected() {
        
        if sortedOn != "POPULAR" {
            sortedOn = "POPULAR"
            postsShown = 20
            loadMostPopularFromFirebase()
            scrollToTop()
            print("Load most popular")
        }
    }
    
    func loadHottestSelected() {
        
        if sortedOn != "STANDARD" {
            sortedOn = "STANDARD"
            postsShown = 20
            loadStandardFromFirebase()
            scrollToTop()
            print("Load standard")
        }
    }
    
    func loadLatestSelected() {
        
        if sortedOn != "LATEST" {
            sortedOn = "LATEST"
            postsShown = 20
            loadLatestFromFirebase()
            scrollToTop()
            print("Load latest")
        }
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        // Loads 20 posts each refresh
        if posts.count % 20 != 0 {
            print("No more data to load")
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
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
            // this runs on the background queue
            
            print("Get more data")
            self.postsShown += 20
            
            if self.sortedOn == "POPULAR" {
                self.loadMostPopularFromFirebase()
            } else if self.sortedOn == "STANDARD" {
                // STANDARD AT THE MOMENT
                self.loadStandardFromFirebase()
            } else if self.sortedOn == "LATEST" {
                self.loadLatestFromFirebase()
            } else {
                // STANDARD
                self.loadStandardFromFirebase()
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                // this runs on the main queue
                
                self.tableView.reloadData()
                self.loadingData = false
                
                print("Done!")
            }
        }
    }
    
    
    func loadStandardFromFirebase() {
        
        print("Init!")
        
        let count = posts.count
        
        // Observe changes in Firebase, update instantly
        DataService.ds.REF_POSTS.queryLimitedToFirst(UInt(postsShown)).observeSingleEventOfType(.Value, withBlock: { snapshot in
            self.posts = []
            
            if let snapshot = snapshot.children.allObjects as? [FDataSnapshot] {
                for snap in snapshot {
                    if let postDict = snap.value as? Dictionary<String, AnyObject> {
                        let key = snap.key
                        let post = Post(postKey: key, dictionary: postDict)
                        self.posts.append(post)
                        print("ADD")
                    }
                }
            }
            
            print("LOAD")
            
            if count == 0 {
                EZLoadingActivity.hide()
            }
            
            if self.firstLogin {
                self.loginMessage()
                self.firstLogin = false
            }
            
            print("Count after: \(self.posts.count)")
            
            self.tableView.reloadData()
        })
        
    }
    
    func loadMostPopularFromFirebase() {
        
        let count = posts.count
        
        print("LOADING POPULAR")
        
        // Observe changes in Firebase, update instantly
        DataService.ds.REF_POSTS.queryLimitedToLast(UInt(postsShown)).queryOrderedByChild("likes").observeSingleEventOfType(.Value, withBlock: { snapshot in
            self.posts = []
            
            if let likes = snapshot.value["likes"] as? Int {
                print("\(snapshot.key) has \(likes) likes")
            }
            
            if let snapshot = snapshot.children.allObjects as? [FDataSnapshot] {
                for snap in snapshot {
                    
                    if let postDict = snap.value as? Dictionary<String, AnyObject> {
                        let key = snap.key
                        let post = Post(postKey: key, dictionary: postDict)
                        self.posts.append(post)
                        print("APPEND")
                    }
                }
            }
            
            if count == 0 {
                EZLoadingActivity.hide()
            }
            
            self.posts = self.posts.reverse()
            self.tableView.reloadData()
            
        })
    }
    
    func loadLatestFromFirebase() {
        
        let count = posts.count
        
        // Observe changes in Firebase, update instantly
        DataService.ds.REF_POSTS.queryLimitedToLast(UInt(postsShown)).observeSingleEventOfType(.Value, withBlock: { snapshot in
            self.posts = []
            
            if let snapshot = snapshot.children.allObjects as? [FDataSnapshot] {
                for snap in snapshot {
                    if let postDict = snap.value as? Dictionary<String, AnyObject> {
                        let key = snap.key
                        let post = Post(postKey: key, dictionary: postDict)
                        self.posts.append(post)
                         print("ADD")
                    }
                }
            }
            
            print("LOAD")
            
            if count == 0 {
                EZLoadingActivity.hide()
            }
            
            if self.firstLogin {
                self.loginMessage()
                self.firstLogin = false
            }
            
            print("Count after: \(self.posts.count)")
            
            self.posts = self.posts.reverse()
            self.tableView.reloadData()
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
    
    // Animate push of post view when user starts scrolling
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        dismisskeyboard()
        stopLikeAnimation()
        self.postTextViewHeight.constant = 110
        
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
                print("Current offset > height")
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
            cell.commentsTapAction = { (cell) in
                self.performSegueWithIdentifier(SEGUE_COMMENTSVC, sender: post)
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
            // This shit must work
            return 115 + heightForView(post.postDescription, width: screenWidth - 51)
            
        } else {
            return tableView.estimatedRowHeight
        }
    }
    
    func refresh(sender:AnyObject) {
        
        if isConnectedToNetwork() {
            tableView.reloadData()
            refreshControl.endRefreshing()
        } else {
            refreshControl.endRefreshing()
            JSSAlertView().danger(self, title: "No Internet Connection", text: "Please connect to a network and the feed will load automatically.")
        }
    }
    
    func profileBtnPressed() {
        dismisskeyboard()
        menuView.hide()
        
        self.performSegueWithIdentifier(SEGUE_PROFILEVC, sender: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        dismisskeyboard()
        
        if segue.identifier == SEGUE_COMMENTSVC {
            if let commentsVC = segue.destinationViewController as? CommentsVC {
                if let post = sender as? Post {
                    commentsVC.post = post
                }
            }
        }
    }
    
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        imagePicker.dismissViewControllerAnimated(true, completion: nil)
        imageSelector.image = image
        imageSelected = true
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        imagePicker.dismissViewControllerAnimated(true, completion: nil)
        imageSelector.image = UIImage(named: "camera")
        imageSelected = false
    }
    
    func dismisskeyboard() {
        view.endEditing(true)
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
        
        postViewHeight.constant = 101
        postTextViewHeight.constant = 40
        
    }
    
    func textViewDidBeginEditing(textView: UITextView) {
        
        postViewHeight.constant = 171
        postTextViewHeight.constant = 110
    }
    
    func loginMessage() {
        if typeOfLogin == "OldAccount" {
            successAlertFeedVC(self, title: "Welcome back", msg: "You have successfully been logged in!")
            EZLoadingActivity.hide()
        } else if typeOfLogin == "NewAccount" {
            successAlertFeedVC(self, title: "Welcome", msg: "A new account has successfully been created! Before you start posting, you should add a username and a profile image. To do so, click the profile icon in the upper right corner.")
            EZLoadingActivity.hide()
        } else {
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
    
    func postToFireBase(imgUrl: String?) {
        
        var post: Dictionary<String, AnyObject> = [
            "description": postTextView.text!,
            "likes": 0,
            "user" : NSUserDefaults.standardUserDefaults().valueForKey(KEY_UID) as! String,
            "timestamp" : Timestamp
        ]
        
        if imgUrl != nil {
            post["imageUrl"] = imgUrl!
        } else {
            post["imageUrl"] = ""
        }
        
        // Add post to firebase
        let firebasePost = DataService.ds.REF_POSTS.childByAutoId()
        firebasePost.setValue(post)
        imageSelected = false
        
        postTextView.text = placeHolderText
        postTextView.textColor = UIColor.lightGrayColor()
        imageSelector.image = UIImage(named: "camera")
        
        EZLoadingActivity.Settings.SuccessText = "Uploded"
        EZLoadingActivity.hide(success: true, animated: true)
        
        if sortedOn == "POPULAR" {
            print("ADDE NEW POST")
            loadMostPopularFromFirebase()
        } else if sortedOn == "STANDARD" {
                 print("ADDE NEW POST")
            loadStandardFromFirebase()
        } else if sortedOn == "LATEST" {
                 print("ADDE NEW POST")
            loadLatestFromFirebase()
        }
        
    }
    
    // If app has been reinstalled, must fetch user data from firebase
    
    func loadProfileData() {
        
        if !userProfileAdded() {
            print("Profile url or username is nil, load from firebase")
            
            DataService.ds.REF_USER_CURRENT.observeEventType(.Value, withBlock: { snapshot in
                
                if let snapshot = snapshot.children.allObjects as? [FDataSnapshot] {
                    
                    for snap in snapshot {
                        
                        if snap.key == "imgUrl" {
                            let profileUrl = snap.value
                            NSUserDefaults.standardUserDefaults().setValue(profileUrl, forKey: "profileUrl")
                            print("Added prof url \(profileUrl)")
                        }
                        
                        if snap.key == "username" {
                            let username = snap.value
                            NSUserDefaults.standardUserDefaults().setValue(username, forKey: "username")
                            print("Added username \(username)")
                        }
                        
                        print("Nothing to add!")
                        
                    }
                }
            })
        } else {
            print("Profile data is up to date")
        }
    }
    
    func accessCamera() {
        imagePicker.sourceType = UIImagePickerControllerSourceType.Camera;
        imagePicker.allowsEditing = true
        self.presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    func accessLibrary() {
        imagePicker.allowsEditing = true
        self.presentViewController(imagePicker, animated: true, completion: nil)
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
    
    func callBack() {
        print("Callback")
    }
    
    @IBAction func makePost(sender: AnyObject) {
        
        print("Post!")
        dismisskeyboard()
        
        if !userProfileAdded() {
            JSSAlertView().danger(self, title: "Update Your Profile", text: "Please add a username and a profile image before posting. You can find the profile by clicking on the icon in the upper right corner.")
            return;
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
                                            print("LINK: \(imageLink)")
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

