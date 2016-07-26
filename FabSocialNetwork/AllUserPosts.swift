//
//  AllUserPosts.swift
//  FabSocialNetwork
//
//  Created by Adam Thuvesen on 2016-07-18.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import UIKit
import Firebase
import EZLoadingActivity
import JSSAlertView
import Async
import Alamofire


class AllUserPosts: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITableViewDelegate, UITableViewDataSource, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tableView: UITableView!
    
    private var confirmRemove = false
    private var indexPathRemove: NSIndexPath?
    private var typeOfCell = TypeOfCell.PostCollectionCell
    private var zoomBarButton : UIButton!
    private var reportPost: Post!
    private var request: Request?
    private var firstView = true
    
    var userPosts = [Post]()
    var userKey = currentUserKey()
    
    enum TypeOfCell: String {
        case PostCollectionCell = "PostCollectionCell"
        case UserPostCell = "UserPostCell"
        case PostCell = "PostCell"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.emptyDataSetDelegate = self
        collectionView.emptyDataSetSource = self
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        
        loadIphoneTypeForRowHeight()
        tableView.rowHeight = UITableViewAutomaticDimension
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Plain, target:nil, action:nil)
        navigationItem.leftItemsSupplementBackButton = true
        
        title = "POSTS"
        
        if userKey != currentUserKey() {
            let viewButton = setupViewButton()
            navigationItem.setRightBarButtonItems([viewButton], animated: true)
        } else {
            let deleteButton = setupDeleteButton()
            let viewButton = setupViewButton()
            let fixed: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FixedSpace, target: nil, action: nil)
            fixed.width = 12
            navigationItem.setRightBarButtonItems([deleteButton, fixed, viewButton], animated: true)
        }
        
        if isConnectedToNetwork() {
            EZLoadingActivity.show("Loading...", disableUI: false)
        }
        
        loadUserPostsFromFirebase()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        EZLoadingActivity.hide()
    }
    
    func saveImagesToCache() {
        
        var count = 0
        
        for post in userPosts {
            let imgUrl = post.imageUrl!
            request = Alamofire.request(.GET, imgUrl).validate(contentType: ["image/*"]).response(completionHandler: { (request, response, data, err) in
                if err == nil {
                    if (FeedVC.imageCache.objectForKey(imgUrl) as? UIImage) == nil {
                        let img = UIImage(data: data!)!
                        FeedVC.imageCache.setObject(img, forKey: imgUrl)
                    }
                }

                count += 1
                
                if count == self.userPosts.count {
                    EZLoadingActivity.hide()
                    self.userPosts = self.userPosts.reverse()
                    self.collectionView.reloadData()
                }
            })
            
        }
    }
    
    func loadUserPostsFromFirebase() {
        
        DataService.ds.REF_POSTS.queryOrderedByChild("user").queryEqualToValue(userKey).observeEventType(.Value, withBlock: { snapshot in
            self.userPosts = []
            
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                for snap in snapshot {
                    if let postDict = snap.value as? Dictionary<String, AnyObject> {
                        let key = snap.key
                        let post = Post(postKey: key, dictionary: postDict)
                        self.userPosts.append(post)
                    }
                }
            }
            
            if self.userPosts.count == 0 {
                EZLoadingActivity.hide()
            }
            
            // Save to cache once
            if self.firstView  {
                self.saveImagesToCache()
                self.firstView = false
            } else {
                EZLoadingActivity.hide()
                self.userPosts = self.userPosts.reverse()
                self.collectionView.reloadData()
            }
            
        })
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        if typeOfCell == TypeOfCell.PostCollectionCell || typeOfCell == TypeOfCell.PostCell {
            
            typeOfCell = .UserPostCell
            
            if tableView.hidden {
                tableView.hidden = false
                collectionView.hidden = true
            }
            
            tableView.reloadData()
        }
        
        if tableView.editing {
            tableView.setEditing(false, animated: true)
        } else {
            tableView.setEditing(true, animated: true)
        }
    }
    
    func loadIphoneTypeForRowHeight() {
        switch iphoneType {
        case "4":
            tableView.estimatedRowHeight = 400
        case "5":
            tableView.estimatedRowHeight = 425
        case "6":
            tableView.estimatedRowHeight = 450
        case "6+":
            tableView.estimatedRowHeight = 550
        default:
            tableView.estimatedRowHeight = 550
        }
    }
    
    func setupDeleteButton() -> UIBarButtonItem {
        
        let button: UIButton = UIButton(type: UIButtonType.Custom)
        button.setImage(UIImage(named: "Trash"), forState: UIControlState.Normal)
        button.addTarget(self, action: #selector(AllUserPosts.setEditing(_:animated:)), forControlEvents: UIControlEvents.TouchUpInside)
        button.frame = CGRectMake(0, 0, 23, 23)
        let barButton = UIBarButtonItem(customView: button)
        
        return barButton
    }
    
    func setupViewButton() -> UIBarButtonItem {
        zoomBarButton = UIButton(type: UIButtonType.Custom)
        zoomBarButton.setImage(UIImage(named: "List"), forState: UIControlState.Normal)
        zoomBarButton.addTarget(self, action: #selector(AllUserPosts.changeTypeOfCell), forControlEvents: UIControlEvents.TouchUpInside)
        zoomBarButton.frame = CGRectMake(0, 0, 23, 23)
        let barButton = UIBarButtonItem(customView: zoomBarButton)
        return barButton
    }
    
    func changeTypeOfCell() {
        
        if typeOfCell == TypeOfCell.PostCollectionCell {
            typeOfCell = .UserPostCell
            tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
            zoomBarButton.setImage(UIImage(named: "ZoomIn"), forState: UIControlState.Normal)
            
            if tableView.editing {
                tableView.setEditing(false, animated: true)
            }
        } else if typeOfCell == TypeOfCell.UserPostCell {
            typeOfCell = .PostCell
            tableView.contentInset = UIEdgeInsetsMake(-8, 0, 0, 0);
            zoomBarButton.setImage(UIImage(named: "Grid"), forState: UIControlState.Normal)
            
            if tableView.editing {
                tableView.setEditing(false, animated: true)
            }
            
        } else {
            typeOfCell = .PostCollectionCell
            zoomBarButton.setImage(UIImage(named: "List"), forState: UIControlState.Normal)
        }
        
        if typeOfCell == TypeOfCell.PostCollectionCell {
            tableView.hidden = true
            collectionView.hidden = false
            collectionView.reloadData()
        } else {
            tableView.hidden = false
            collectionView.hidden = true
            tableView.reloadData()
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        if let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PostCollectionCell", forIndexPath: indexPath) as? PostCollectionCell {
            
            let post = userPosts[indexPath.row]
            
            cell.configureCell(post)
            
            return cell
            
        } else {
            return UICollectionViewCell()
        }
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
                return 110 + heightForView(post.postDescription, width: screenWidth - 24)
            } else {
                return tableView.estimatedRowHeight + heightForView(post.postDescription, width: screenWidth - 24)
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
            
            cell.reportTapAction = { (cell) in
                self.reportPost = post
                self.reportAlert()
            }
            
            cell.layoutIfNeeded()
            
            return cell
        } else {
            return UITableViewCell()
        }
    }
    
    func reportAlert() {
        let alertview = JSSAlertView().show(self, title: "Report", text: "Do you want to report this post for containing objectionable content? \n", buttonText: "Yes", cancelButtonText: "No", color: UIColorFromHex(0xe64c3c, alpha: 1))
        alertview.setTextTheme(.Light)
        alertview.addAction(reportAnswerYes)
        alertview.addCancelAction(reportAnswerNo)
    }
    
    func reportAnswerYes() {
        reportUserPost(self.reportPost.postKey)
    }
    
    func reportAnswerNo() {
        // Do nothing
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        stopLikeAnimation()
    }
    
    func removeConfirmed() {
        
        let postToRemove = userPosts[indexPathRemove!.row]
        removePostFromFirebase(postToRemove)
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
    
    func removePostFromFirebase(postToRemove: Post!) {
        
        DataService.ds.REF_POSTS.child(postToRemove.postKey).removeValueWithCompletionBlock { (error, ref) in
            
            if error != nil {
                EZLoadingActivity.showWithDelay("Failure", disableUI: true, seconds: 1.0)
                EZLoadingActivity.Settings.SuccessText = "Failure"
                EZLoadingActivity.hide(success: false, animated: true)
            } else {
                EZLoadingActivity.showWithDelay("Removed", disableUI: true, seconds: 1.0)
                EZLoadingActivity.Settings.FailText = "Removed"
                EZLoadingActivity.hide(success: false, animated: true)
                self.updateScores()
            }
        }
        
    }
    
    func updateScores() {
        func updateScores(hasImage: Bool) {
            DataService.ds.REF_USER_CURRENT.child("score").observeSingleEventOfType(.Value, withBlock: { snapshot in
                
                if var score = snapshot.value as? Int {
                    
                    let diceRoll = Int(arc4random_uniform(10) + 1)
                    
                    score -= 5 + diceRoll
                    
                    if score < 0 {
                        score = 0
                    }
                    
                    DataService.ds.REF_USER_CURRENT.child("score").setValue(score)
                }
                
            })
        }
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return userKey == currentUserKey()
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        
        let deleteAction = UITableViewRowAction(style: .Normal, title: "Remove") { (rowAction:UITableViewRowAction, indexPath:NSIndexPath) -> Void in
            
            if !isConnectedToNetwork() {
                JSSAlertView().danger(self, title: "No Internet Connection", text: "Please connect to a network and try again.")
                tableView.setEditing(false, animated: true)
                return
            }
            
            self.indexPathRemove = indexPath
            self.confirmRemovePost()
        }
        
        deleteAction.backgroundColor = UIColorFromHex(0xe64c3c, alpha: 1)
        
        return [deleteAction]
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        var str = ""
        if isConnectedToNetwork() {
            if userKey != currentUserKey() {
                str = "It looks like the user has not made any posts."
            } else {
                str = "It looks like you have not made any posts. Go back to the main view to create one."
            }
        } else {
            str = "Please connect to a network."
        }
        let attrs = [NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleBody)]
        return NSAttributedString(string: str, attributes: attrs)
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
    
    func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage! {
        var imgName = ""
        
        if isConnectedToNetwork() {
            imgName = "Write"
        } else {
            imgName = "Wifi"
        }
        
        return UIImage(named: imgName)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 2.0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 2.0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        if typeOfCell == TypeOfCell.PostCollectionCell {
            
            let post = userPosts[indexPath.row]
            performSegueWithIdentifier(SEGUE_SHOWUSERPOSTVC, sender: post)
        }
        
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return userPosts.count
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        let numberOfColumns: CGFloat = 3
        let itemWidth = (CGRectGetWidth(self.collectionView!.frame) - 2 - (numberOfColumns - 1)) / numberOfColumns
        
        return CGSizeMake(itemWidth, itemWidth)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        switch segue.identifier {
            
        case SEGUE_COMMENTSVC?:
            if let commentsVC = segue.destinationViewController as? CommentsVC {
                if let post = sender as? Post {
                    commentsVC.post = post
                }
            }
        case SEGUE_SHOWUSERPOSTVC?:
            if let userPostVC = segue.destinationViewController as? ShowUserPostVC {
                if let post = sender as? Post {
                    userPostVC.post = post
                }
            }
        default:
            break
        }
    }
}
