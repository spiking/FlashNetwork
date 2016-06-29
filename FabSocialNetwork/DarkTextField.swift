//
//  MaterialTextField.swift
//  MySocialMedia
//
//  Created by Adam Thuvesen on 2016-06-02.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import UIKit

class DarkTextField: UITextField {

    override func awakeFromNib() {

    }
    
    // For placeholder
    override func textRectForBounds(bounds: CGRect) -> CGRect {
            return CGRectInset(bounds, 10, 0)
    }
    
    override func editingRectForBounds(bounds: CGRect) -> CGRect {
        return CGRectInset(bounds, 10, 0)
    }
    
}
