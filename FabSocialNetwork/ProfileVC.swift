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
import Async
import Fusuma

class ProfileVC: UIViewController, FusumaDelegate {
    
    private var imageSelected = false
    private var request: Request?
    private var usernameTaken = false
    private var keyboardVisible = false
    private var standardKeyboardHeight: CGFloat = 216
    private var settingsButton: UIButton!
    private var favoritesButton: UIButton!
    private var currentProfileImage: UIImage?
    private var fusuma = FusumaViewController()
    
    @IBOutlet weak var addImgBtn: UIButton!
    @IBOutlet weak var imageSelector: UIImageView!
    @IBOutlet weak var usernameField: DarkTextField!
    @IBOutlet weak var scoreLbl: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageSelector.layer.cornerRadius = imageSelector.frame.width / 2
        imageSelector.clipsToBounds = true
        
        let tap : UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ProfileVC.dismisskeyboard))
        view.addGestureRecognizer(tap)
        
        let placeholderPassword = NSAttributedString(string: "Username", attributes: [NSForegroundColorAttributeName:UIColor.lightTextColor()])
        usernameField.attributedPlaceholder = placeholderPassword
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Plain, target:nil, action:nil)
        
        title = "PROFILE"
        
        checkiPhoneType()
        
        if iphoneType == "4" || iphoneType == "5" {
            
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CommentsVC.keyboardWillShow(_:)), name:UIKeyboardWillShowNotification, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CommentsVC.keyboardWillHide(_:)), name:UIKeyboardWillHideNotification, object: nil)
        }
        
        let settingsButton = setupSettingsButton()
        let favoritesButton = setupFavoritesButton()
        
        let fixed: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FixedSpace, target: nil, action: nil)
        fixed.width = 12
        navigationItem.setRightBarButtonItems([settingsButton, fixed, favoritesButton], animated: true)
        
        setupFusuma()
        
        loadProfileData()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if UIApplication.sharedApplication().isIgnoringInteractionEvents() {
            UIApplication.sharedApplication().endIgnoringInteractionEvents()
        }
        
        UIApplication.sharedApplication().statusBarStyle = .LightContent
        UIApplication.sharedApplication().statusBarHidden = false
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.dismisskeyboard()
    }
    
    func setupFusuma() {
        fusumaCropImage = true
        fusumaTintColor = UIColorFromHex(0x25c051, alpha: 1)
        fusumaBackgroundColor = UIColor(red: CGFloat(18/255.0), green: CGFloat(18/255.0), blue: CGFloat(18/255.0), alpha: CGFloat(1.0))
        fusuma.delegate = self
    }
    
    func loadProfileData() {
        
        if let profileUrl = NSUserDefaults.standardUserDefaults().valueForKey("profileUrl") as? String {
            if let profileImg = FeedVC.imageCache.objectForKey(profileUrl) as? UIImage {
                self.imageSelector.image = profileImg
                addImgBtn.imageView?.image = UIImage(named: "ImageSelected")
                currentProfileImage = profileImg
            } else {
                request = Alamofire.request(.GET, profileUrl).validate(contentType: ["image/*"]).response(completionHandler: { (request, response, data, err) in
                    if err == nil {
                        let img = UIImage(data: data!)!
                        self.imageSelector.image = img
                        self.addImgBtn.imageView?.image = UIImage(named: "ImageSelected")
                        self.currentProfileImage = img
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
        
        DataService.ds.REF_USER_CURRENT.child("score").observeSingleEventOfType(.Value, withBlock: { snapshot in
            
            if let score = snapshot.value as? Int {
                self.scoreLbl.text = "\(score)"
            }
        })
    }
    
    func setupSettingsButton() -> UIBarButtonItem {
        settingsButton = UIButton(type: UIButtonType.Custom)
        settingsButton.setImage(UIImage(named: "Settings"), forState: UIControlState.Normal)
        settingsButton.addTarget(self, action: #selector(ProfileVC.settingsBtnTapped), forControlEvents: UIControlEvents.TouchUpInside)
        settingsButton.frame = CGRectMake(0, 0, 22, 22)
        let barButton = UIBarButtonItem(customView: settingsButton)
        return barButton
    }
    
    
    func setupFavoritesButton() -> UIBarButtonItem {
        favoritesButton = UIButton(type: UIButtonType.Custom)
        favoritesButton.setImage(UIImage(named: "StarEmpty"), forState: UIControlState.Normal)
        favoritesButton.addTarget(self, action: #selector(ProfileVC.favoritesBtnTapped), forControlEvents: UIControlEvents.TouchUpInside)
        favoritesButton.frame = CGRectMake(0, 0, 25, 25)
        let barButton = UIBarButtonItem(customView: favoritesButton)
        return barButton
    }
    
    func settingsBtnTapped() {
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()
        self.performSegueWithIdentifier(SEGUE_SETTINGSVC, sender: nil)
        Async.background(after: 0.5) {
            if UIApplication.sharedApplication().isIgnoringInteractionEvents() {
                UIApplication.sharedApplication().endIgnoringInteractionEvents()
            }
        }
    }
    
    func favoritesBtnTapped() {
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()
        self.performSegueWithIdentifier(SEGUE_FAVORITESVC, sender: nil)
        Async.background(after: 0.5) {
            if UIApplication.sharedApplication().isIgnoringInteractionEvents() {
                UIApplication.sharedApplication().endIgnoringInteractionEvents()
            }
        }
    }
    
    func keyboardWillShow(sender: NSNotification) {
        
        if keyboardVisible {
            return
        }
        
        UIView.animateWithDuration(0.1, animations: { () -> Void in
            
            switch iphoneType  {
                case "4":
                    self.view.frame.origin.y -= 0.75 * self.standardKeyboardHeight
                    self.keyboardVisible = true
                case "5":
                    self.view.frame.origin.y -= 0.35 * self.standardKeyboardHeight
                    self.keyboardVisible = true
            default:
                break
            }
        })
    }
    
    func keyboardWillHide(sender: NSNotification) {
        
        if !keyboardVisible {
            return
        }
        
        UIView.animateWithDuration(0.1, animations: { () -> Void in
            
            switch iphoneType  {
            case "4":
                self.view.frame.origin.y += 0.75 * self.standardKeyboardHeight
                self.keyboardVisible = false
            case "5":
                self.view.frame.origin.y += 0.33 * self.standardKeyboardHeight
                self.keyboardVisible = false
            default:
                break
            }
        })
    }
    
    func addNewProfileImageToFirebase(imgUrl: String?) {
        if imgUrl != nil {
            DataService.ds.REF_USER_CURRENT.child("imgUrl").setValue(imgUrl)
            NSUserDefaults.standardUserDefaults().setValue(imgUrl, forKey: "profileUrl")

            EZLoadingActivity.Settings.SuccessText = "Updated"
            EZLoadingActivity.hide(success: true, animated: true)
        }
        imageSelected = false
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
        DataService.ds.REF_USER_CURRENT.child("username").setValue(newUsername)
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
    
    
    func fusumaImageSelected(image: UIImage) {
        imageSelector.image = image
        imageSelected = true
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        print("Image selected")
    }
    
    func fusumaDismissedWithImage(image: UIImage) {
        print("Called just after FusumaViewController is dismissed.")
    }
    
    func fusumaVideoCompleted(withFileURL fileURL: NSURL) {
        print("Called just after a video has been selected.")
    }
    
    func fusumaCameraRollUnauthorized() {
        print("Camera roll unauthorized")
    }
    
    func fusumaClosed() {
        self.imageSelector.image = currentProfileImage
        imageSelected = false
        UIApplication.sharedApplication().statusBarHidden = false
    }

    
    @IBAction func addImgBtnTapped(sender: AnyObject) {
        dismisskeyboard()
        addImgBtn.imageView?.image = UIImage(named: "ImageSelected")
        
        self.presentViewController(fusuma, animated: true, completion: nil)
        UIApplication.sharedApplication().statusBarHidden = true
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
