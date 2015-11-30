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

    // MARK: Timeline

    @IBAction func shareTextToTimeline(sender: UIButton) {
        var content = Content()
        content.title = "Timeline Text, \(NSUUID().UUIDString)"
        do {
            try MonkeyKing.shareContent(content, serviceProvider: WeChatServiceProvier(appID: weChatAppID, appKey: weChatAppKey, destination: .Timeline)) {
                succeed in print(succeed)
            }
        }
        catch let error {
            print(error)
        }
    }

    @IBAction func shareURLToTimeline(sender: UIButton) {
        let content = Content(title: "Timeline URL, \(NSUUID().UUIDString)", description: "Description URL, \(NSUUID().UUIDString)", thumbnail: UIImage(named: "rabbit"), media: .URL(NSURL(string: "http://soyep.com")!))
        do {
            try MonkeyKing.shareContent(content, serviceProvider: WeChatServiceProvier(appID: weChatAppID, appKey: weChatAppKey, destination: .Timeline)) {
                succeed in print(succeed)
            }
        }
        catch let error {
            print(error)
        }
    }

    @IBAction func shareImageToTimeline(sender: UIButton) {
        let content = Content(title: "Timeline URL, \(NSUUID().UUIDString)", description: "Description URL, \(NSUUID().UUIDString)", thumbnail: UIImage(named: "rabbit"), media: .Image(UIImage(named: "rabbit")!))
        do {
            try MonkeyKing.shareContent(content, serviceProvider: WeChatServiceProvier(appID: weChatAppID, appKey: weChatAppKey, destination: .Timeline)) {
                succeed in print(succeed)
            }
        }
        catch let error {
            print(error)
        }
    }

    @IBAction func shareMusicToTimeline(sender: UIButton) {
        let content = Content(title: "Timeline Music, \(NSUUID().UUIDString)", description: "Description Music, \(NSUUID().UUIDString)", thumbnail: UIImage(named: "rabbit"), media: .Audio(audioURL: NSURL(string: "http://stream20.qqmusic.qq.com/32464723.mp3")!, linkURL: NSURL(string: "http://soyep.com")!))
        do {
            try MonkeyKing.shareContent(content, serviceProvider: WeChatServiceProvier(appID: weChatAppID, appKey: weChatAppKey, destination: .Timeline)) {
                succeed in print(succeed)
            }
        }
        catch let error {
            print(error)
        }
    }

    @IBAction func shareVideoToTimeline(sender: UIButton) {
        let content = Content(title: "Timeline Video, \(NSUUID().UUIDString)", description: "Description Video, \(NSUUID().UUIDString)", thumbnail: UIImage(named: "rabbit"), media: .Video(NSURL(string: "http://v.youku.com/v_show/id_XNTUxNDY1NDY4.html")!))
        do {
            try MonkeyKing.shareContent(content, serviceProvider: WeChatServiceProvier(appID: weChatAppID, appKey: weChatAppKey, destination: .Timeline)) {
                succeed in print(succeed)
            }
        }
        catch let error {
            print(error)
        }
    }

    // MARK: Session

    @IBAction func shareTextToSession(sender: UIButton) {

        var content = Content()
        content.title = "Timeline Text, \(NSUUID().UUIDString)"
        do {
            try MonkeyKing.shareContent(content, serviceProvider: WeChatServiceProvier(appID: weChatAppID, appKey: weChatAppKey, destination: .Session)) {
                succeed in print(succeed)
            }
        }
        catch let error {
            print(error)
        }
    }

    @IBAction func shareURLToSession(sender: UIButton) {
        let content = Content(title: "Timeline URL, \(NSUUID().UUIDString)", description: "Description URL, \(NSUUID().UUIDString)", thumbnail: UIImage(named: "rabbit"), media: .URL(NSURL(string: "http://soyep.com")!))
        do {
            try MonkeyKing.shareContent(content, serviceProvider: WeChatServiceProvier(appID: weChatAppID, appKey: weChatAppKey, destination: .Session)) {
                succeed in print(succeed)
            }
        }
        catch let error {
            print(error)
        }
    }

    @IBAction func shareImageToSession(sender: UIButton) {
        let content = Content(title: "Timeline URL, \(NSUUID().UUIDString)", description: "Description URL, \(NSUUID().UUIDString)", thumbnail: UIImage(named: "rabbit"), media: .Image(UIImage(named: "rabbit")!))
        do {
            try MonkeyKing.shareContent(content, serviceProvider: WeChatServiceProvier(appID: weChatAppID, appKey: weChatAppKey, destination: .Session)) {
                succeed in print(succeed)
            }
        }
        catch let error {
            print(error)
        }
    }

    @IBAction func shareMusicToSession(sender: UIButton) {
        let content = Content(title: "Timeline Music, \(NSUUID().UUIDString)", description: "Description Music, \(NSUUID().UUIDString)", thumbnail: UIImage(named: "rabbit"), media: .Audio(audioURL: NSURL(string: "http://stream20.qqmusic.qq.com/32464723.mp3")!, linkURL: NSURL(string: "http://soyep.com")!))
        do {
            try MonkeyKing.shareContent(content, serviceProvider: WeChatServiceProvier(appID: weChatAppID, appKey: weChatAppKey, destination: .Session)) {
                succeed in print(succeed)
            }
        }
        catch let error {
            print(error)
        }
    }

    @IBAction func shareVideoToSession(sender: UIButton) {
        let content = Content(title: "Timeline Video, \(NSUUID().UUIDString)", description: "Description Video, \(NSUUID().UUIDString)", thumbnail: UIImage(named: "rabbit"), media: .Video(NSURL(string: "http://v.youku.com/v_show/id_XNTUxNDY1NDY4.html")!))
        do {
            try MonkeyKing.shareContent(content, serviceProvider: WeChatServiceProvier(appID: weChatAppID, appKey: weChatAppKey, destination: .Session)) {
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
            try MonkeyKing.OAuth(WeChatServiceProvier(appID: weChatAppID, appKey: weChatAppKey, destination: .Session), completionHandler: {
                (data, response, error) -> Void in self.fetchUserInfo(data)
            })
        }
        catch let error {
            print(error)
        }
    }

    @IBAction func OAuthWithoutAppKey(sender: UIButton) {
        do {
            try MonkeyKing.OAuth(WeChatServiceProvier(appID: weChatAppID, appKey: nil, destination: .Session), completionHandler: {
                (data, response, error) -> Void in print(data)
            })
        }
        catch let error {
            print(error)
        }
    }

    private func fetchUserInfo(OAuthInfo: NSDictionary?) {

        guard let token = OAuthInfo?["access_token"] as? String, let openID = OAuthInfo?["openid"] as? String, let refreshToken = OAuthInfo?["refresh_token"] as? String, let expiresIn = OAuthInfo?["expires_in"] as? Int else {
            return
        }

        let userInfoAPI = "https://api.weixin.qq.com/sns/userinfo"

        let parameters = ["openid": openID, "access_token": token]

        SimpleNetworking.sharedInstance.request(NSURL(string: userInfoAPI)!, method: .GET, parameters: parameters, completionHandler: {
            (userInfoDictionary, _, _) -> Void in

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
}
