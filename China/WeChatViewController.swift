//
//  WeChatViewController.swift
//  China
//
//  Created by Limon on 15/9/26.
//  Copyright © 2015年 nixWork. All rights reserved.
//

import UIKit
import MonkeyKing

let weChatAppID = "wx4868b35061f87885"
let weChatAppKey = "64020361b8ec4c99936c0e3999a9f249"

class WeChatViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: Timeline

    @IBAction func shareTextToTimeline(sender: UIButton) {

        let message = MonkeyKing.Message.WeChat(.Timeline(info: (
            title: "Timeline Text, \(NSUUID().UUIDString)",
            description: nil,
            thumbnail: nil,
            media: nil
        )))

        MonkeyKing.shareMessage(message) { success in
            print("success: \(success)")
        }
    }

    @IBAction func shareURLToTimeline(sender: UIButton) {

        let message = MonkeyKing.Message.WeChat(.Timeline(info: (
            title: "Timeline URL, \(NSUUID().UUIDString)",
            description: "Description URL, \(NSUUID().UUIDString)",
            thumbnail: UIImage(named: "rabbit"),
            media: .URL(NSURL(string: "http://soyep.com")!)
        )))

        MonkeyKing.shareMessage(message) { success in
            print("success: \(success)")
        }
    }

    @IBAction func shareImageToTimeline(sender: UIButton) {

        let message = MonkeyKing.Message.WeChat(.Timeline(info: (
            title: nil,
            description: nil,
            thumbnail: UIImage(named: "rabbit"),
            media: .Image(UIImage(named: "rabbit")!)
        )))

        MonkeyKing.shareMessage(message) { success in
            print("success: \(success)")
        }
    }

    @IBAction func shareMusicToTimeline(sender: UIButton) {

        let message = MonkeyKing.Message.WeChat(.Timeline(info: (
            title: "Timeline Music, \(NSUUID().UUIDString)",
            description: "Description Music, \(NSUUID().UUIDString)",
            thumbnail: UIImage(named: "rabbit"),
            media: .Audio(audioURL: NSURL(string: "http://stream20.qqmusic.qq.com/32464723.mp3")!, linkURL: NSURL(string: "http://soyep.com")!)
        )))

        MonkeyKing.shareMessage(message) { success in
            print("success: \(success)")
        }
    }

    @IBAction func shareVideoToTimeline(sender: UIButton) {

        let message = MonkeyKing.Message.WeChat(.Timeline(info: (
            title: "Timeline Video, \(NSUUID().UUIDString)",
            description: "Description Video, \(NSUUID().UUIDString)",
            thumbnail: UIImage(named: "rabbit"),
            media: .Video(NSURL(string: "http://v.youku.com/v_show/id_XNTUxNDY1NDY4.html")!)
        )))

        MonkeyKing.shareMessage(message) { success in
            print("success: \(success)")
        }
    }

    // MARK: Session

    @IBAction func shareTextToSession(sender: UIButton) {

        let message = MonkeyKing.Message.WeChat(.Session(info: (
            title: "Session Text, \(NSUUID().UUIDString)",
            description: nil,
            thumbnail: nil,
            media: nil)
        ))

        MonkeyKing.shareMessage(message) { success in
            print("success: \(success)")
        }
    }

    @IBAction func shareURLToSession(sender: UIButton) {

        let message = MonkeyKing.Message.WeChat(.Session(info: (
            title: "Session URL, \(NSUUID().UUIDString)",
            description: "description URL, \(NSUUID().UUIDString)",
            thumbnail: UIImage(named: "rabbit"),
            media: .URL(NSURL(string: "http://soyep.com")!)
        )))

        MonkeyKing.shareMessage(message) { success in
            print("success: \(success)")
        }
    }

    @IBAction func shareImageToSession(sender: UIButton) {

        let message = MonkeyKing.Message.WeChat(.Session(info: (
            title: nil,
            description: nil,
            thumbnail: UIImage(named: "rabbit"),
            media: .Image(UIImage(named: "rabbit")!)
        )))

        MonkeyKing.shareMessage(message) { success in
            print("success: \(success)")
        }
    }

    @IBAction func shareImageURLToSession(sender: UIButton) {

        let message = MonkeyKing.Message.WeChat(.Session(info: (
            title: nil,
            description: nil,
            thumbnail: UIImage(named: "rabbit"),
            media: .ImageURL(NSURL(string: "http://images.ifanr.cn/wp-content/uploads/2015/11/appso-banner1.jpg")!)
        )))

        MonkeyKing.shareMessage(message) { success in
            print("success: \(success)")
        }
    }

    @IBAction func shareMusicToSession(sender: UIButton) {

        let message = MonkeyKing.Message.WeChat(.Session(info: (
            title: "Session Music, \(NSUUID().UUIDString)",
            description: "Description Music, \(NSUUID().UUIDString)",
            thumbnail: UIImage(named: "rabbit"),
            media: .Audio(audioURL: NSURL(string: "http://stream20.qqmusic.qq.com/32464723.mp3")!, linkURL: NSURL(string: "http://soyep.com")!)
        )))

        MonkeyKing.shareMessage(message) { success in
            print("success: \(success)")
        }
    }

    @IBAction func shareVideoToSession(sender: UIButton) {

        let message = MonkeyKing.Message.WeChat(.Session(info: (
            title: "Session Video, \(NSUUID().UUIDString)",
            description: "Description Video, \(NSUUID().UUIDString)",
            thumbnail: UIImage(named: "rabbit"),
            media: .Video(NSURL(string: "http://v.youku.com/v_show/id_XNTUxNDY1NDY4.html")!)
        )))

        MonkeyKing.shareMessage(message) { success in
            print("success: \(success)")
        }
    }

    // MARK: OAuth

    @IBAction func OAuth(sender: UIButton) {

        // Should not register account here
        let account = MonkeyKing.Account.WeChat(appID: weChatAppID, appKey: weChatAppKey)
        MonkeyKing.registerAccount(account)

        MonkeyKing.OAuth(.WeChat) { [weak self] (dictionary, response, error) -> Void in
            self?.fetchUserInfo(dictionary)
        }
    }

    @IBAction func OAuthWithoutAppKey(sender: UIButton) {

        // Should not register account here
        let accountWithoutAppKey = MonkeyKing.Account.WeChat(appID: "\(weChatAppID)ssssss", appKey: nil)
        MonkeyKing.registerAccount(accountWithoutAppKey)

        MonkeyKing.OAuth(.WeChat) { (dictionary, response, error) -> Void in

            // You can use this code to OAuth, if you do not want to keep the weChatAppKey in client.
            print("dictionary \(dictionary)")
        }
    }

    private func fetchUserInfo(OAuthInfo: NSDictionary?) {

        guard let token = OAuthInfo?["access_token"] as? String,
            let openID = OAuthInfo?["openid"] as? String,
            let refreshToken = OAuthInfo?["refresh_token"] as? String,
            let expiresIn = OAuthInfo?["expires_in"] as? Int else {
                return
        }

        let userInfoAPI = "https://api.weixin.qq.com/sns/userinfo"

        let parameters = [
            "openid": openID,
            "access_token": token
        ]

        // fetch UserInfo by userInfoAPI
        SimpleNetworking.sharedInstance.request(userInfoAPI, method: .GET, parameters: parameters, completionHandler: { (userInfoDictionary, _, _) -> Void in

            guard let mutableDictionary = userInfoDictionary?.mutableCopy() as? NSMutableDictionary else {
                return
            }

            mutableDictionary["access_token"] = token
            mutableDictionary["openid"] = openID
            mutableDictionary["refresh_token"] = refreshToken
            mutableDictionary["expires_in"] = expiresIn

            print("userInfoDictionary \(mutableDictionary)")
        })

        // More API
        // http://mp.weixin.qq.com/wiki/home/index.html
    }

    private func fetchWeChatOAuthInfoByCode(code code: String) {

        let appID = ""
        let appKey = "" // fetch appKey from server

        var accessTokenAPI = "https://api.weixin.qq.com/sns/oauth2/access_token?"
        accessTokenAPI += "appid=" + appID
        accessTokenAPI += "&secret=" + appKey
        accessTokenAPI += "&code=" + code + "&grant_type=authorization_code"

        // OAuth
        SimpleNetworking.sharedInstance.request(accessTokenAPI, method: .GET) { (OAuthJSON, response, error) -> Void in
            print("OAuthJSON \(OAuthJSON)")
        }
    }
}

