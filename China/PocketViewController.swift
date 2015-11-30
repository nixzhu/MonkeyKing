//
//  PocketViewController.swift
//  China
//
//  Created by catch on 15/11/25.
//  Copyright © 2015年 nixWork. All rights reserved.
//

import UIKit
import MonkeyKing

// More API
// https://getpocket.com/developer/docs/v3/add

let pocketAppID = "48363-344532f670a052acff492a25"

class PocketViewController: UIViewController {

    static var accessToken: String?

    @IBAction func saveButtonAction(sender: UIButton) {
        var content = Content()
        content.media = .URL(NSURL(string: "http://36kr.com/p/5040304.html")!)

        do {
            try MonkeyKing.shareContent(content, serviceProvider: PocketServiceProvider(appID: pocketAppID, accessToken: "8b3a58bc-ac08-b34f-6ef0-76803b")) {
                succeed in print(succeed)
            }
        }
        catch let error {
            print(error)
        }

    }

    @IBAction func OAuth(sender: UIButton) {
        do {
            try MonkeyKing.OAuth(PocketServiceProvider(appID: pocketAppID, accessToken: nil)) {
                (dic, response, error) -> Void in if let accessToken = dic?["access_token"] as? String {
                    PocketViewController.accessToken = accessToken
                }
            }

        }
        catch let error {
            print(error)
        }
    }
}
