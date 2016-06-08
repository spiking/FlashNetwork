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

class ProfileVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate  {
    
    
    @IBOutlet weak var addImgBtn: UIButton!
    @IBOutlet weak var imageSelector: UIImageView!
    @IBOutlet weak var usernameTextField: MaterialTextField!
    var imagePicker: UIImagePickerController!
    var imageSelected = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        
        imageSelector.layer.cornerRadius = imageSelector.frame.width / 2
        imageSelector.clipsToBounds = true
        
        addImgBtn.alpha = 1.0
        
        print("Loaded profile view!")
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
            let data : Dictionary<String, String> = ["imgUrl" : imgUrl!, "username" : username!]
            DataService.ds.REF_USER_CURRENT.childByAppendingPath("username").setValue(username!)
            DataService.ds.REF_USER_CURRENT.childByAppendingPath("imgUrl").setValue(imgUrl)
            
            print("Add data to firebase")
            showAlert("Profile updated", msg: "Your profile has now been updated.")
            
            //Global user data added (current session)
            CURRENT_USER_LOCAL = User(username: username!, imageUrl: imgUrl!)

        }
        
        imageSelected = false
        usernameTextField.text = ""
    }
    
    @IBAction func addImgBtnTapped(sender: AnyObject) {
        presentViewController(imagePicker, animated: true, completion: nil)
        print("Add!")
    }
    
    @IBAction func saveBtnTapped(sender: AnyObject) {
        print("Save")
        
        if let username = usernameTextField.text where username != "" {
            if let img = imageSelector.image where imageSelected == true {
                
                let urlStr = "https://post.imageshack.us/upload_api.php"
                let url = NSURL(string: urlStr)!
                
                let imgData = UIImageJPEGRepresentation(img, 0.2)!
                let keyData = "12DJKPSU5fc3afbd01b1630cc718cae3043220f3".dataUsingEncoding(NSUTF8StringEncoding)!
                let keyJson = "json".dataUsingEncoding(NSUTF8StringEncoding)!
                
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
            showAlert("Error", msg: "Please choose a profile picture and username.")
        }
    }
    
    func showAlert(title: String, msg: String) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .Alert)
        let action = UIAlertAction(title: "Ok", style: .Default, handler: nil)
        alert.addAction(action)
        presentViewController(alert, animated: true, completion: nil)
    }
}
