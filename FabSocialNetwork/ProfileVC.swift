//
//  ProfileVC.swift
//  FabSocialNetwork
//
//  Created by Adam Thuvesen on 2016-06-07.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import UIKit
import Alamofire
import Firebase
import SCLAlertView
import EZLoadingActivity
import JSSAlertView

class ProfileVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate  {
    
    @IBOutlet weak var addImgBtn: UIButton!
    @IBOutlet weak var imageSelector: UIImageView!
    @IBOutlet weak var usernameTextField: MaterialTextField!
    
    var imagePicker: UIImagePickerController!
    var imageSelected = false
    var request: Request?
    var usernameTaken = false
    
    var myGroup = dispatch_group_create()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.navigationBar.tintColor = UIColor.blackColor()
        
        imageSelector.layer.cornerRadius = imageSelector.frame.width / 2
        imageSelector.clipsToBounds = true
        
        let tap : UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ProfileVC.dismisskeyboard))
        view.addGestureRecognizer(tap)
        
        let placeholderPassword = NSAttributedString(string: "Username", attributes: [NSForegroundColorAttributeName:UIColor.lightTextColor()])
        usernameTextField.attributedPlaceholder = placeholderPassword
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Plain, target:nil, action:nil)
        
        addImgBtn.alpha = 1.0
        
        self.title = "PROFILE"
        
        setupSettingsButton()
        
        loadProfileData()
    }
    
    func loadProfileData() {
        
        if let profileUrl = NSUserDefaults.standardUserDefaults().valueForKey("profileUrl") as? String {
            if let profileImg = FeedVC.imageCache.objectForKey(profileUrl) as? UIImage {
                self.imageSelector.image = profileImg
                self.addImgBtn.alpha = 0.05
            } else {
                request = Alamofire.request(.GET, profileUrl).validate(contentType: ["image/*"]).response(completionHandler: { (request, response, data, err) in
                    if err == nil {
                        let img = UIImage(data: data!)!
                        self.imageSelector.image = img
                        self.addImgBtn.alpha = 0.05
                        print("Add to cache!")
                        FeedVC.imageCache.setObject(img, forKey: profileUrl)
                    }
                })
            }
        }
        
        if let username = NSUserDefaults.standardUserDefaults().valueForKey("username") as? String {
            usernameTextField.text = username.capitalizedString
        }
    }
    
    func setupSettingsButton() {
        let button: UIButton = UIButton(type: UIButtonType.Custom)
        button.setImage(UIImage(named: "Settings"), forState: UIControlState.Normal)
        button.addTarget(self, action: #selector(ProfileVC.settingsBtnTapped), forControlEvents: UIControlEvents.TouchUpInside)
        button.frame = CGRectMake(0, 0, 25, 25)
        let barButton = UIBarButtonItem(customView: button)
        self.navigationItem.rightBarButtonItem = barButton
    }
    
    func settingsBtnTapped() {
        self.performSegueWithIdentifier("settings", sender: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        imagePicker.dismissViewControllerAnimated(true, completion: nil)
        imageSelector.image = image
        addImgBtn.alpha = 0.05
        imageSelected = true
    }
    
    func changeOfUsername() -> Bool {
        let usernameEntered = usernameTextField.text?.lowercaseString
        return NSUserDefaults.standardUserDefaults().valueForKey("username") as? String != usernameEntered && usernameTextField.text != ""
    }
    
    func changeOfProfileImage() -> Bool {
        if let _ = imageSelector.image where imageSelected == true {
            return true
        } else {
            return false
        }
    }
    
    func usernameContainsSpaces() -> Bool {
        let whitespace = NSCharacterSet.whitespaceCharacterSet()
        let range = usernameTextField.text!.rangeOfCharacterFromSet(whitespace)
        
        if range != nil {
            print("whitespace found")
            return true
        }
        else {
            print("whitespace not found")
            return false
        }
    }
    
    func addNewProfileImageToFirebase(imgUrl: String?) {
        if imgUrl != nil {
            DataService.ds.REF_USER_CURRENT.childByAppendingPath("imgUrl").setValue(imgUrl)
            NSUserDefaults.standardUserDefaults().setValue(imgUrl, forKey: "profileUrl")
            EZLoadingActivity.Settings.SuccessText = "Updated"
            EZLoadingActivity.hide(success: true, animated: true)
        }
        imageSelected = false
    }
    
    func dismisskeyboard() {
        view.endEditing(true)
    }
    
    func userHasUsername() -> Bool {
        return NSUserDefaults.standardUserDefaults().valueForKey("username") != nil
    }
    
    func userHasProfileImg() -> Bool {
        return NSUserDefaults.standardUserDefaults().valueForKey("profileUrl") != nil
    }
    
    // Top-level utility function for delay with async requests
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
    
    func addUsernameToFirebaseEfficient(newUsername: String!) {
        
        EZLoadingActivity.show("Updating...", disableUI: true)
        DataService.ds.REF_USERS.queryOrderedByChild("username").queryEqualToValue(newUsername).observeSingleEventOfType(.Value, withBlock: { snap in
            
            if snap.value is NSNull {
                print("NSNull \(snap.value)")
                self.usernameTaken = false
                self.usernameIsNotTaken(newUsername)
            } else {
                print("NOT NSNull \(snap.value)")
                self.usernameTaken = true
                self.usernameIsTaken()
            }
        })
    }
    
    func usernameIsTaken() {
        let username = NSUserDefaults.standardUserDefaults().valueForKey("username") as? String
        self.usernameTextField.text = username?.capitalizedString
        
        JSSAlertView().danger(self, title: "Username Taken", text: "The username entered is already taken. Please try something else.")
        EZLoadingActivity.hide()
    }
    
    func usernameIsNotTaken(newUsername: String!) {
        DataService.ds.REF_USER_CURRENT.childByAppendingPath("username").setValue(newUsername)
        NSUserDefaults.standardUserDefaults().setValue(newUsername.lowercaseString, forKey: "username")
        self.usernameTaken = false
        EZLoadingActivity.Settings.SuccessText = "Updated"
        EZLoadingActivity.hide(success: true, animated: true)
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
    
    @IBAction func addImgBtnTapped(sender: AnyObject) {
        dismisskeyboard()
        
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
    
    @IBAction func saveBtnTapped(sender: AnyObject) {
        dismisskeyboard()
        
        if !changeOfUsername() && !changeOfProfileImage() {
            return
        }
        
        if !isConnectedToNetwork() {
            JSSAlertView().danger(self, title: "No Internet Connection", text: "To update your profile please connect to a network.")
            return
        }
        
        if usernameTextField.text?.characters.count > 25 {
            JSSAlertView().danger(self, title: "Too Long Username", text: "The username can not be longer than 25 characters.")
            return
        }
        
        if usernameContainsSpaces() {
            JSSAlertView().danger(self, title: "Username Contains Spaces", text: "The username can not be longer than 25 characters.")
            return
        }
        
        if !userHasProfileImg() || changeOfProfileImage() {
            
            if let img = imageSelector.image where imageSelected == true {
                
                EZLoadingActivity.show("Updating...", disableUI: true)
                
                let urlStr = "https://post.imageshack.us/upload_api.php"
                let url = NSURL(string: urlStr)!
                
                let imgData = UIImageJPEGRepresentation(img, 0.3)!
                let keyData = "12DJKPSU5fc3afbd01b1630cc718cae3043220f3".dataUsingEncoding(NSUTF8StringEncoding)!
                let keyJson = "json".dataUsingEncoding(NSUTF8StringEncoding)!
                
                // Upload profile image with ImageShack
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
                                            self.addNewProfileImageToFirebase(imageLink)
                                            
                                            // Save profile image to local cache
                                            self.request = Alamofire.request(.GET, imageLink).validate(contentType: ["image/*"]).response(completionHandler: { (request, response, data, err) in
                                                if err == nil {
                                                    print("Add profile image to cache")
                                                    let img = UIImage(data: data!)!
                                                    FeedVC.imageCache.setObject(img, forKey: imageLink)
                                                    
                                                }
                                            })
                                            
                                            
                                        }
                                        
                                    }
                                    
                                }
                                
                            })
                            
                        case.Failure(let error):
                            print(error)
                        }
                        
                })
            }
        }
        
        if !userHasUsername() || changeOfUsername() {
            print("Update firebase and local data for new username")
            let newUsername = usernameTextField.text?.lowercaseString
            addUsernameToFirebaseEfficient(newUsername)
        }
    }
}
