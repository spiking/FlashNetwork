//
//  PostCollectionCell.swift
//  FabSocialNetwork
//
//  Created by Adam Thuvesen on 2016-07-18.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import UIKit
import Alamofire

class PostCollectionCell: UICollectionViewCell {
    
    private var _request: Request?
    private var _post: Post?
    
    var post: Post? {
        return _post
    }
    
    var request: Request? {
        return _request
    }
    
    @IBOutlet weak var image: UIImageView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)    
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.image.image = nil
    }
    
    func configureCell(post: Post) {
        self._post = post
        
        if post.imageUrl != "" {
            if let mainImg = FeedVC.imageCache.objectForKey(post.imageUrl!) as? UIImage {
                self.image.image = mainImg
            } else {
                _request = Alamofire.request(.GET, post.imageUrl!).validate(contentType: ["image/*"]).response(completionHandler: { (request, response, data, err) in
                    if err == nil {
                        let img = UIImage(data: data!)!
                        self.image.image = img
                        FeedVC.imageCache.setObject(img, forKey: post.imageUrl!)
                    }
                })
            }
        } else {
            self.image.image = UIImage(named: "NoProfileImageBig.png")
        }
    }
}
