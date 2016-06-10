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

class ProfileVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate  {
    
    @IBOutlet weak var addImgBtn: UIButton!
    @IBOutlet weak var imageSelector: UIImageView!
    @IBOutlet weak var usernameTextField: MaterialTextField!
    
    var imagePicker: UIImagePickerController!
    var imageSelected = false
    var request: Request?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        
        imageSelector.layer.cornerRadius = imageSelector.frame.width / 2
        imageSelector.clipsToBounds = true
        
        let tap : UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismisskeyboard")
        view.addGestureRecognizer(tap)
        
        addImgBtn.alpha = 1.0
        self.title = "Profile"
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
            usernameTextField.text = username
        }
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        imagePicker.dismissViewControllerAnimated(true, completion: nil)
        imageSelector.image = image
        addImgBtn.alpha = 0.05
        imageSelected = true
        print("Selected image!")
    }
    
    func addProfileDataToFirebase(imgUrl: String?) {
        
        let username = usernameTextField.text
        
        if imgUrl != nil && username != "" {
            // Save profile data to Firebase
            let data : Dictionary<String, String> = ["imgUrl" : imgUrl!, "username" : username!]
            DataService.ds.REF_USER_CURRENT.childByAppendingPath("username").setValue(username!)
            DataService.ds.REF_USER_CURRENT.childByAppendingPath("imgUrl").setValue(imgUrl)
            
            print("Add data to firebase")
            successAlert("Success", subTitle: "Your profile has successfully been updated.")
            
            // Save profile data locally
            NSUserDefaults.standardUserDefaults().setValue(imgUrl, forKey: "profileUrl")
            NSUserDefaults.standardUserDefaults().setValue(username, forKey: "username")
        }
        
        imageSelected = false
    }
    
    func dismisskeyboard() {
        view.endEditing(true)
    }
    
    @IBAction func addImgBtnTapped(sender: AnyObject) {
        presentViewController(imagePicker, animated: true, completion: nil)
        print("Add!")
    }
    
    @IBAction func saveBtnTapped(sender: AnyObject) {
        print("Save")
        
        if (NSUserDefaults.standardUserDefaults().valueForKey("profileUrl") as? String) != nil {
            errorAlert("Not supported", subTitle: "At the moment the application does not support a change of profile picture or username.")
            return;
        }
        
        if let username = usernameTextField.text where username != "" {
            if let img = imageSelector.image where imageSelected == true {
                
                let urlStr = "https://post.imageshack.us/upload_api.php"
                let url = NSURL(string: urlStr)!
                
                let imgData = UIImageJPEGRepresentation(img, 0.4)!
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
                                            self.addProfileDataToFirebase(imageLink)
                                            
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
        } else {
            errorAlert("Action not allowed", subTitle: "Please choose a profile picture and username.")
        }
    }
}
