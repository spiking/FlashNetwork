//
//  Alerts.swift
//  FabSocialNetwork
//
//  Created by Adam Thuvesen on 2016-06-10.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import Foundation
import SCLAlertView
import EZLoadingActivity

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

func infoAlert(title: String, subTitle: String) {
    
    SCLAlertView().showTitle(
        title, // Title of view
        subTitle: subTitle, // String of view
        duration: 3.0, // Duration to show before closing automatically, default: 0.0
        completeText: "Ok", // Optional button value, default: ""
        style: .Info, // Styles - see below.
        colorStyle: 0xED8500,
        colorTextButton: 0xFFFFFF
    )
}

func alertViewSetup() {
    EZLoadingActivity.Settings.BackgroundColor = UIColor.blackColor()
    EZLoadingActivity.Settings.TextColor = UIColor.whiteColor()
    EZLoadingActivity.Settings.FontName = "Avenir"
    EZLoadingActivity.Settings.ActivityColor = UIColor.whiteColor()
}