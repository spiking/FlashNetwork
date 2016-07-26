//
//  FavoriteCell.swift
//  FabSocialNetwork
//
//  Created by Adam Thuvesen on 2016-07-20.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import UIKit
import Firebase
import Alamofire

class FavoriteCell: UITableViewCell {
    
    private var _userRef: FIRDatabaseReference!
    private var _request: Request?
    private var _userKey: String!
    
    var request: Request? {
        return _request
    }
    
    @IBOutlet weak var usernameLbl: UILabel!
    @IBOutlet weak var profileImg: UIImageView!
    @IBOutlet weak var scoreLbl: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()

    }
    
    override func drawRect(rect: CGRect) {
        profileImg.layer.cornerRadius = profileImg.frame.size.width / 2
        profileImg.clipsToBounds = true
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureCell(userKey: String) {
        
        self._userKey = userKey
        self._userRef = DataService.ds.REF_USERS.child(_userKey)
        
        _userRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
            
            if let username = snapshot.value!["username"] as? String {
                self.usernameLbl.text = username.capitalizedString
            } else {
                self.usernameLbl.text = "Default Username"
            }
            
            if let score = snapshot.value!["score"] as? Int {
                self.scoreLbl.text = "\(score)"
            } else {
                self.scoreLbl.text = "0"
            }
            
            if let profileUrl = snapshot.value!["imgUrl"] as? String {
                if let profImage = FeedVC.imageCache.objectForKey(profileUrl) as? UIImage {
                    self.profileImg.image = profImage
                } else {
                    self._request = Alamofire.request(.GET, profileUrl).validate(contentType: ["image/*"]).response(completionHandler: { (request, response, data, err) in
                        if err == nil {
                            let img = UIImage(data: data!)!
                            self.profileImg.image = img
                            FeedVC.imageCache.setObject(img, forKey: profileUrl)
                        }
                    })
                    
                }
            } else {
                self.profileImg.image = UIImage(named:"NoProfileImage.png")
            }
            
            }, withCancelBlock: { error in
                print(error.description)
        })
        
    }

}
