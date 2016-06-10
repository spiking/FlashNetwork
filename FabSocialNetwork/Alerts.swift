//
//  Alerts.swift
//  FabSocialNetwork
//
//  Created by Adam Thuvesen on 2016-06-10.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import Foundation
import SCLAlertView

// Global alert functions

func waitAlert(title: String, subTitle: String) {
    
    SCLAlertView().showTitle(
        title, // Title of view
        subTitle: subTitle, // String of view
        duration: 3.0, // Duration to show before closing automatically, default: 0.0
        completeText: "Ok", // Optional button value, default: ""
        style: .Wait, // Styles - see below.
        colorStyle: 0x1C1C1C,
        colorTextButton: 0xFFFFFF
    )
}

func successAlert(title: String, subTitle: String) {
    SCLAlertView().showTitle(
        title, // Title of view
        subTitle: subTitle, // String of view
        duration: 3.0, // Duration to show before closing automatically, default: 0.0
        completeText: "Done", // Optional button value, default: ""
        style: .Success, // Styles - see below.
        colorStyle: 0x6AE368,
        colorTextButton: 0xFFFFFF
    )
}

func errorAlert(title: String, subTitle: String) {

    
    SCLAlertView().showTitle(
        title, // Title of view
        subTitle: subTitle, // String of view
        duration: 3.0, // Duration to show before closing automatically, default: 0.0
        completeText: "Ok", // Optional button value, default: ""
        style: .Error, // Styles - see below.
        colorStyle: 0xCC2214,
        colorTextButton: 0xFFFFFF
    )
}