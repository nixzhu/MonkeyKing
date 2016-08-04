//
//  WeiboViewController.swift
//  China
//
//  Created by Limon on 15/9/26.
//  Copyright © 2015年 nixWork. All rights reserved.
//

import UIKit
import MonkeyKing

class WeiboViewController: UIViewController {

    let account = MonkeyKing.Account.Weibo(appID: Configs.Weibo.appID, appKey: Configs.Weibo.appKey, redirectURL: Configs.Weibo.redirectURL)
    var accessToken: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        MonkeyKing.registerAccount(account)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        // not installed weibo app, must need accessToken

        if !account.isAppInstalled {

            MonkeyKing.OAuth(.Weibo, completionHandler: { [weak self] (dictionary, response, error) -> Void in

                if let json = dictionary, accessToken = json["access_token"] as? String {
                    self?.accessToken = accessToken
                }

                print("dictionary \(dictionary) error \(error)")
            })
        }
    }

    @IBAction func shareImage(sender: UIButton) {

        let message = MonkeyKing.Message.Weibo(.Default(info: (
            title: "Image",
            description: "Rabbit",
            thumbnail: nil,
            media: .Image(UIImage(named: "rabbit")!)
        ), accessToken: accessToken))

        MonkeyKing.shareMessage(message) { result in
            print("result: \(result)")
        }
    }

    @IBAction func shareText(sender: UIButton) {

        let message = MonkeyKing.Message.Weibo(.Default(info: (
            title: "Title",
            description: "Text",
            thumbnail: nil,
            media: nil
        ), accessToken: accessToken))

        MonkeyKing.shareMessage(message) { result in
            print("result: \(result)")
        }
    }

    @IBAction func shareURL(sender: UIButton) {

        let message = MonkeyKing.Message.Weibo(.Default(info: (
            title: "News",
            description: "Hello Yep",
            thumbnail: UIImage(named: "rabbit"),
            media: .URL(NSURL(string: "http://soyep.com")!)
        ), accessToken: accessToken))

        MonkeyKing.shareMessage(message) { result in
            print("result: \(result)")
        }
    }

    // MARK: OAuth

    @IBAction func OAuth(sender: UIButton) {

        MonkeyKing.OAuth(.Weibo) { (OAuthInfo, response, error) -> Void in

            // App or Web: token & userID
            guard let token = (OAuthInfo?["access_token"] ?? OAuthInfo?["accessToken"]) as? String, userID = (OAuthInfo?["uid"] ?? OAuthInfo?["userID"]) as? String else {
                return
            }

            let userInfoAPI = "https://api.weibo.com/2/users/show.json"
            let parameters = ["uid": userID, "access_token": token]

            // fetch UserInfo by userInfoAPI
            SimpleNetworking.sharedInstance.request(userInfoAPI, method: .GET, parameters: parameters, completionHandler: { (userInfoDictionary, _, _) -> Void in
                print("userInfoDictionary \(userInfoDictionary)")
            })

            // More API
            // http://open.weibo.com/wiki/%E5%BE%AE%E5%8D%9AAPI
        }
    }
}
