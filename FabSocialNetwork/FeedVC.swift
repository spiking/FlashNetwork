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



class FeedVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var posts = [Post]()
    static var imageCache = NSCache() // Static since single instance (global)
    var imagePicker: UIImagePickerController!
    var imageSelected = false
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var postField: MaterialTextField!
    @IBOutlet weak var imageSelector: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        
        tableView.estimatedRowHeight = 400
        let tap : UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismisskeyboard")
        view.addGestureRecognizer(tap)
        
        let nav = self.navigationController?.navigationBar
        nav?.titleTextAttributes =  [NSFontAttributeName: UIFont(name: "Avenir", size: 20)!]
        nav?.tintColor = UIColor.lightTextColor()
        nav?.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.lightTextColor()]
        self.title = "Fab Network"
        
        // Profile btn in navigation bar
        let button: UIButton = UIButton(type: UIButtonType.Custom)
        button.setImage(UIImage(named: "profile2.png"), forState: UIControlState.Normal)
        button.addTarget(self, action: "profileBtnPressed", forControlEvents: UIControlEvents.TouchUpInside)
        button.frame = CGRectMake(0, 0, 40, 40)
        let barButton = UIBarButtonItem(customView: button)
        self.navigationItem.rightBarButtonItem = barButton
        
        if NSUserDefaults.standardUserDefaults().objectForKey("profileUrl") == nil {
            successAlert("Success", subTitle: "A new account has successfully been created!")
        }
        
        initObservers()
    }
    
    func profileBtnPressed() {
        self.performSegueWithIdentifier("ProfileVC", sender: nil)
    }
    
    func initObservers() {
        
        // Observe changes in Firebase, update instantly (code in closure)
        DataService.ds.REF_POSTS.observeEventType(.Value, withBlock: { snapshot in
            self.posts = []
            
            if let snapshot = snapshot.children.allObjects as? [FDataSnapshot] {
                for snap in snapshot {
                    if let postDict = snap.value as? Dictionary<String, AnyObject> {
                        let key = snap.key
                        let post = Post(postKey: key, dictionary: postDict)
                        self.posts.append(post)
                        
                    }
                }
            }
            
            self.tableView.reloadData()
        })

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
                self.performSegueWithIdentifier("CommentsVC", sender: post)
            }
            
            return cell
            
        } else {
            return PostCell()
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let post = posts[indexPath.row]
        
        if post.imageUrl == nil || post.imageUrl == "" {
            return 200
        } else {
            return tableView.estimatedRowHeight
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "CommentsVC" {
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
    
    func dismisskeyboard() {
        view.endEditing(true)
    }
    
    @IBAction func selectImage(sender: UITapGestureRecognizer) {
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    
    @IBAction func makePost(sender: AnyObject) {
        
//      waitAlert("Post uploading", subTitle: "Your post is being uploaded.")
        print("Post!")
        dismisskeyboard()
        
        let profileUrl = NSUserDefaults.standardUserDefaults().valueForKey("profileUrl") as? String
        
        if profileUrl == nil {
            errorAlert("Not supported", subTitle: "Please add a profile picture and username.")
            return;
        }
        
        if let txt = postField.text where txt != "" {
            
            if let img = imageSelector.image where imageSelected == true {
                
                let urlStr = "https://post.imageshack.us/upload_api.php"
                let url = NSURL(string: urlStr)!
                
                // Convert to JPG & compress 60 %
                let imgData = UIImageJPEGRepresentation(img, 0.4)!
                
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
            errorAlert("No description", subTitle: "Please add a description.")
        }
    }
    
    func postToFireBase(imgUrl: String?) {
        
        var post: Dictionary<String, AnyObject> = [
            "description": postField.text!,
            "likes": 0,
            "user" : NSUserDefaults.standardUserDefaults().valueForKey(KEY_UID) as! String
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
        
        // Reset
        postField.text = ""
        imageSelector.image = UIImage(named: "camera")
        
        successAlert("Post uploaded", subTitle: "Operation successfully completed.")
        print("Succcess!")
        
        tableView.reloadData()
    }
}
