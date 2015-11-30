//
//  WeiboViewController.swift
//  China
//
//  Created by Limon on 15/9/26.
//  Copyright © 2015年 nixWork. All rights reserved.
//

import UIKit
import MonkeyKing

let weiboAppID = "504855958"
let weiboAppKey = "f5107a6c6cd2cc76c9b261208a3b17a1"
let weiboRedirectURL = "http://www.limon.top"

class WeiboViewController: UIViewController {
    var accessToken: String?

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        // not installed weibo app, must need accessToken
        if !WeiboServiceProvier.appInstalled {
            do {
                try MonkeyKing.OAuth(WeiboServiceProvier(appID: weiboAppID, appKey: weiboAppKey, redirectURL: weiboRedirectURL, accessToken: nil), completionHandler: {
                    (dictionary, response, error) -> Void in if let json = dictionary, accessToken = json["access_token"] as? String {
                        self.accessToken = accessToken
                    }

                    print("dictionary \(dictionary) error \(error)")
                })
            }
            catch let error {
                print(error)
            }
        }
    }

    @IBAction func shareImage(sender: UIButton) {
        let content = Content(title: "Image", description: "Rabbit", thumbnail: UIImage(named: "rabbit"), media: .Image(UIImage(named: "rabbit")!))

        do {
            try MonkeyKing.shareContent(content, serviceProvider: WeiboServiceProvier(appID: weiboAppID, appKey: weiboAppKey, redirectURL: weiboRedirectURL, accessToken: accessToken)) {
                succeed in print(succeed)
            }
        }
        catch let error {
            print(error)
        }

    }

    @IBAction func shareText(sender: UIButton) {
        var content = Content()
        content.title = "Title"
        content.description = "Text"
        do {
            try MonkeyKing.shareContent(content, serviceProvider: WeiboServiceProvier(appID: weiboAppID, appKey: weiboAppKey, redirectURL: weiboRedirectURL, accessToken: accessToken)) {
                succeed in print(succeed)
            }
        }
        catch let error {
            print(error)
        }
    }

    @IBAction func shareURL(sender: UIButton) {
        var content = Content()
        content.title = "News"
        content.description = "Hello Yep"
        content.thumbnail = UIImage(named: "rabbit")
        content.media = .URL(NSURL(string: "http://soyep.com")!)
        do {
            try MonkeyKing.shareContent(content, serviceProvider: WeiboServiceProvier(appID: weiboAppID, appKey: weiboAppKey, redirectURL: weiboRedirectURL, accessToken: accessToken)) {
                succeed in print(succeed)
            }
        }
        catch let error {
            print(error)
        }

    }

    // MARK: OAuth

    @IBAction func OAuth(sender: UIButton) {
        do {
            try MonkeyKing.OAuth(WeiboServiceProvier(appID: weiboAppID, appKey: weiboAppKey, redirectURL: weiboRedirectURL, accessToken: accessToken)) {
                (OAuthInfo, response, error) -> Void in

                // App or Web: token & userID
                guard let token = (OAuthInfo?["access_token"] ?? OAuthInfo?["accessToken"]) as? String, userID = (OAuthInfo?["uid"] ?? OAuthInfo?["userID"]) as? String else {
                    return
                }

                let userInfoAPI = "https://api.weibo.com/2/users/show.json"
                let parameters = ["uid": userID, "access_token": token, "source": weiboAppID]

                // fetch UserInfo by userInfoAPI
                SimpleNetworking.sharedInstance.request(NSURL(string: userInfoAPI)!, method: .GET, parameters: parameters, completionHandler: {
                    (userInfoDictionary, _, _) -> Void in print("userInfoDictionary \(userInfoDictionary)")
                })

                // More API
                // http://open.weibo.com/wiki/%E5%BE%AE%E5%8D%9AAPI
            }
        }
        catch let error {
            print(error)
        }
    }
}
