//
//  UserPostCell.swift
//  FabSocialNetwork
//
//  Created by Adam Thuvesen on 2016-06-24.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import UIKit
import Alamofire

class UserPostCell: UITableViewCell {

    @IBOutlet weak var postLabel: UILabel!
    @IBOutlet weak var postImage:
    UIImageView!
    @IBOutlet weak var likesLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!

    var request: Request?
    private var _post: Post?
    
    var post: Post? {
        return _post
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        postImage.layer.cornerRadius = 3.0
        postImage.clipsToBounds = true
    }
    
    func configureCell(post: Post, img: UIImage?) {
        self._post = post
        self.postLabel.text = post.postDescription
        self.likesLabel.text = String(post.likes)
        self.postImage.image = nil
        
        let date = NSDate(timeIntervalSince1970: Double(post.timestamp)!)
        let diff = NSDate().offsetFrom(date)
        self.timeLabel.text = diff
        
        // Main post image
        if post.imageUrl != "" {
            if img != nil {
                self.postImage.image = img
            } else {
                // Not in cache, download and add to cache
                request = Alamofire.request(.GET, post.imageUrl!).validate(contentType: ["image/*"]).response(completionHandler: { (request, response, data, err) in
                    if err == nil {
                        let img = UIImage(data: data!)!
                        self.postImage.image = img
                        print("Add to cache!")
                        FeedVC.imageCache.setObject(img, forKey: self.post!.imageUrl!)
                    }
                })
            }
        } else {
            self.postImage.image = UIImage(named: "NoImage2.png")
        }
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
