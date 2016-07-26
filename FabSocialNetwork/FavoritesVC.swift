//
//  FavoritesVC.swift
//  FabSocialNetwork
//
//  Created by Adam Thuvesen on 2016-07-20.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import UIKit
import Firebase

class FavoritesVC: UIViewController, UITableViewDelegate, UITableViewDataSource, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    private var favorites = [String]()
    
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
        
        title = "FAVORITES"
        
        loadFavoriteUsersFromFirebase()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        loadFavoriteUsersFromFirebase()
        
        if favorites.count == 0 {
            tableView.tableFooterView = UIView()
        }
    }
    
    func loadFavoriteUsersFromFirebase() {
        
        DataService.ds.REF_USER_CURRENT.child("favorites").observeSingleEventOfType(.Value, withBlock: { snapshot in
            
            self.favorites = [String]()
            
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                for snap in snapshot {
                    self.favorites.append(snap.key)
                }
            }
        
            self.tableView.reloadData()
            
        })
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let userKey = favorites[indexPath.row]
        self.performSegueWithIdentifier(SEGUE_OTHERUSERPROFILEVC, sender: userKey)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == SEGUE_OTHERUSERPROFILEVC {
            if let otherUserProfileVC = segue.destinationViewController as? OtherUserProfileVC {
                if let userKey = sender as? String {
                    otherUserProfileVC.otherUserKey = userKey
                }
            }
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return favorites.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if let cell = tableView.dequeueReusableCellWithIdentifier("FavoriteCell") as? FavoriteCell {
            
            // Cancel request if user scrolls
            cell.request?.cancel()
            let favorite = favorites[indexPath.row]
            cell.configureCell(favorite)
            
            let backgroundView = UIView()
            backgroundView.backgroundColor = UIColor.blackColor()
            cell.selectedBackgroundView = backgroundView
            
            return cell
        } else {
            return FavoriteCell()
        }
    }
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        var str = ""
        if isConnectedToNetwork() {
            str = "No Favorites"
        } else {
            str = "No Internet Connection"
        }
        
        let attrs = [NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)]
        return NSAttributedString(string: str, attributes: attrs)
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        var str = ""
        if isConnectedToNetwork() {
            str = "It looks like you have no favorite users."
        } else {
            str = "Please connect to a network. The users will load automatically."
        }
        let attrs = [NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleBody)]
        return NSAttributedString(string: str, attributes: attrs)
    }
    
    func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage! {
        var imgName = ""
        if isConnectedToNetwork() {
            imgName = "StarFilled"
        } else {
            imgName = "Wifi"
        }
        
        return UIImage(named: imgName)
    }
}
