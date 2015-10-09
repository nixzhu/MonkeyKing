//
//  WeiboViewController.swift
//  China
//
//  Created by catch on 15/9/26.
//  Copyright © 2015年 nixWork. All rights reserved.
//

import UIKit
import MonkeyKing

let weiboAppID = "504855958"
let weiboAppKey = "f5107a6c6cd2cc76c9b261208a3b17a1"
let weiboRedirectURL = "http://www.limon.top"

class WeiboViewController: UIViewController {

    let account = MonkeyKing.Account.Weibo(appID: weiboAppID, appKey: weiboAppKey, redirectURL: weiboRedirectURL)
    var accessToken: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        MonkeyKing.registerAccount(account)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        if !account.isAppInstalled {

            MonkeyKing.OAuth(account) { [weak self] (dictionary, response, error) -> Void in

                if let json = dictionary, accessToken = json["access_token"] as? String {
                    self?.accessToken = accessToken
                }

                print("dictionary \(dictionary) error \(error)")
            }

        }
    }


    @IBAction func shareImage(sender: UIButton) {

        let message = MonkeyKing.Message.Weibo(.Default(info: (
            title: "Image",
            description: "Rabbit",
            thumbnail: nil,
            media: .Image(UIImage(named: "rabbit")!)
        ), accessToken: accessToken))

        MonkeyKing.shareMessage(message) { success in
            print("success: \(success)")
        }

    }


    @IBAction func shareText(sender: UIButton) {

        let message = MonkeyKing.Message.Weibo(.Default(info: (
            title: "Title",
            description: "Text",
            thumbnail: nil,
            media: nil
        ), accessToken: accessToken))

        MonkeyKing.shareMessage(message) { success in
            print("success: \(success)")
        }

    }


    @IBAction func shareURL(sender: UIButton) {

        let message = MonkeyKing.Message.Weibo(.Default(info: (
            title: "News",
            description: "Hello Apple",
            thumbnail: UIImage(named: "rabbit"),
            media: .URL(NSURL(string: "http://www.apple.com/cn")!)
        ), accessToken: accessToken))

        MonkeyKing.shareMessage(message) { success in
            print("success: \(success)")
        }

    }


    @IBAction func OAuth(sender: UIButton) {
        MonkeyKing.OAuth(account) { (dictionary, response, error) -> Void in
            print("dictionary \(dictionary) error \(error)")
        }
    }

}
