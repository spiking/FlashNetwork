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
import EZLoadingActivity
import JSSAlertView

class ProfileVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate  {
    
    var imagePicker: UIImagePickerController!
    var imageSelected = false
    var request: Request?
    var usernameTaken = false
    
    @IBOutlet weak var addImgBtn: UIButton!
    @IBOutlet weak var imageSelector: UIImageView!
    @IBOutlet weak var usernameField: DarkTextField!
    @IBOutlet weak var scoreLbl: UILabel!
    
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
        usernameField.attributedPlaceholder = placeholderPassword
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Plain, target:nil, action:nil)
        
        title = "PROFILE"
        
        setupSettingsButton()
        
        loadProfileData()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)

    }
    
    func loadProfileData() {
        
        if let profileUrl = NSUserDefaults.standardUserDefaults().valueForKey("profileUrl") as? String {
            if let profileImg = FeedVC.imageCache.objectForKey(profileUrl) as? UIImage {
                self.imageSelector.image = profileImg
                addImgBtn.imageView?.image = UIImage(named: "ImageSelected")
            } else {
                request = Alamofire.request(.GET, profileUrl).validate(contentType: ["image/*"]).response(completionHandler: { (request, response, data, err) in
                    if err == nil {
                        let img = UIImage(data: data!)!
                        self.imageSelector.image = img
                        self.addImgBtn.imageView?.image = UIImage(named: "ImageSelected")
                        FeedVC.imageCache.setObject(img, forKey: profileUrl)
                    }
                })
            }
        } else {
            addImgBtn.imageView?.image = UIImage(named: "AddNewImage")
        }
        
        if let username = NSUserDefaults.standardUserDefaults().valueForKey("username") as? String {
            usernameField.text = username.capitalizedString
        }
        
        DataService.ds.REF_USER_CURRENT.childByAppendingPath("score").observeSingleEventOfType(.Value, withBlock: { snapshot in
            
            if let score = snapshot.value as? Int {
                self.scoreLbl.text = "\(score)"
            }
        })
    }
    
    func setupSettingsButton() {
        let button: UIButton = UIButton(type: UIButtonType.Custom)
        button.setImage(UIImage(named: "Settings"), forState: UIControlState.Normal)
        button.addTarget(self, action: #selector(ProfileVC.settingsBtnTapped), forControlEvents: UIControlEvents.TouchUpInside)
        button.frame = CGRectMake(0, 0, 22, 22)
        let barButton = UIBarButtonItem(customView: button)
        self.navigationItem.rightBarButtonItem = barButton
    }
    
    func settingsBtnTapped() {
        self.performSegueWithIdentifier(SEGUE_SETTINGSVC, sender: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        imagePicker.dismissViewControllerAnimated(true, completion: nil)
        imageSelector.image = image
        addImgBtn.imageView?.image = UIImage(named: "ImageSelected")
        imageSelected = true
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
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        imagePicker.dismissViewControllerAnimated(true, completion: nil)
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
    
    func dismisskeyboard() {
        view.endEditing(true)
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
    
    func addUsernameToFirebase(newUsername: String!) {
        
        EZLoadingActivity.show("Updating...", disableUI: true)
        DataService.ds.REF_USERS.queryOrderedByChild("username").queryEqualToValue(newUsername).observeSingleEventOfType(.Value, withBlock: { snap in
            
            if snap.value is NSNull {
                self.usernameTaken = false
                self.usernameIsNotTaken(newUsername)
            } else {
                self.usernameTaken = true
                self.usernameIsTaken()
            }
        })
    }
    
    func usernameContainsSpaces() -> Bool {
        let whitespace = NSCharacterSet.whitespaceCharacterSet()
        let range = usernameField.text!.rangeOfCharacterFromSet(whitespace)
        
        return range != nil
    }
    
    func usernameIsTaken() {
        let username = NSUserDefaults.standardUserDefaults().valueForKey("username") as? String
        self.usernameField.text = username?.capitalizedString
        
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
    
    func userHasUsername() -> Bool {
        return NSUserDefaults.standardUserDefaults().valueForKey("username") != nil
    }
    
    func userHasProfileImg() -> Bool {
        return NSUserDefaults.standardUserDefaults().valueForKey("profileUrl") != nil
    }
    
    func changeOfUsername() -> Bool {
        let usernameEntered = usernameField.text?.lowercaseString
        return NSUserDefaults.standardUserDefaults().valueForKey("username") as? String != usernameEntered && usernameEntered != ""
    }
    
    func changeOfProfileImage() -> Bool {
        return imageSelected == true
    }
    
    @IBAction func addImgBtnTapped(sender: AnyObject) {
        dismisskeyboard()
        addImgBtn.imageView?.image = UIImage(named: "ImageSelected")
        
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
        
        if usernameField.text?.characters.count > 25 {
            JSSAlertView().danger(self, title: "Too Long Username", text: "The username can not be longer than 25 characters.")
            return
        }
        
        if usernameContainsSpaces() {
            JSSAlertView().danger(self, title: "Username Contains Whitespace", text: "The username is not allowed to contain whitespaces.")
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
                                            self.addNewProfileImageToFirebase(imageLink)
                                            
                                            // Save profile image to local cache
                                            self.request = Alamofire.request(.GET, imageLink).validate(contentType: ["image/*"]).response(completionHandler: { (request, response, data, err) in
                                                if err == nil {
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
            if let newUsername = usernameField.text?.lowercaseString where newUsername != "" {
                addUsernameToFirebase(newUsername)
            }
        }
    }
}
