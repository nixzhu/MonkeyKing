//
//  QQViewController.swift
//  China
//
//  Created by Limon on 15/9/26.
//  Copyright © 2015年 nixWork. All rights reserved.
//

import UIKit
import MonkeyKing

let qqAppID = "1104881792"

class QQViewController: UIViewController {
    // MARK: QQ Friends
    @IBAction func shareTextToQQ(sender: UIButton) {
        var content = Content()
        content.description = "QQ Text: Hello World, \(NSUUID().UUIDString)"
        do {
            try MonkeyKing.shareContent(content, serviceProvider: QQServiceProvider(appID: qqAppID, destination: .Friends)) {
                succeed in print(succeed)
            }
        }
        catch let error {
            print(error)
        }
    }

    @IBAction func shareURLToQQ(sender: UIButton) {
        var content = Content()
        content.title = "QQ Friends URL, \(NSUUID().UUIDString)"
        content.description = "apple.com/cn, \(NSUUID().UUIDString)"
        content.thumbnail = UIImage(named: "rabbit")!
        content.media = .URL(NSURL(string: "http://www.apple.com/cn")!)
        do {
            try MonkeyKing.shareContent(content, serviceProvider: QQServiceProvider(appID: qqAppID, destination: .Friends)) {
                succeed in print(succeed)
            }
        }
        catch let error {
            print(error)
        }
    }

    @IBAction func shareImageToQQ(sender: UIButton) {
        var content = Content()
        content.title = "QQ Friends Image, \(NSUUID().UUIDString)"
        content.description = "Hello World, \(NSUUID().UUIDString)"
        content.thumbnail = nil
        content.media = .Image(UIImage(named: "rabbit")!)
        do {
            try MonkeyKing.shareContent(content, serviceProvider: QQServiceProvider(appID: qqAppID, destination: .Friends)) {
                succeed in print(succeed)
            }
        }
        catch let error {
            print(error)
        }
    }

    @IBAction func shareAudioToQQ(sender: UIButton) {
        var content = Content()
        content.title = "QQ Friends Audio, \(NSUUID().UUIDString)"
        content.description = "Hello World, \(NSUUID().UUIDString)"
        content.thumbnail = UIImage(named: "rabbit")!
        content.media = .Audio(audioURL: NSURL(string: "http://wfmusic.3g.qq.com/s?g_f=0&fr=&aid=mu_detail&id=2511915")!, linkURL: nil)
        do {
            try MonkeyKing.shareContent(content, serviceProvider: QQServiceProvider(appID: qqAppID, destination: .Friends)) {
                succeed in print(succeed)
            }
        }
        catch let error {
            print(error)
        }
    }

    @IBAction func shareVideoToQQ(sender: UIButton) {
        var content = Content()
        content.title = "QQ Friends Video, \(NSUUID().UUIDString)"
        content.description = "Hello World, \(NSUUID().UUIDString)"
        content.thumbnail = UIImage(named: "rabbit")!
        content.media = .Video(NSURL(string: "http://v.youku.com/v_show/id_XOTU2MzA0NzY4.html")!)
        do {
            try MonkeyKing.shareContent(content, serviceProvider: QQServiceProvider(appID: qqAppID, destination: .Friends)) {
                succeed in print(succeed)
            }
        }
        catch let error {
            print(error)
        }
    }

    // MARK: QZone

    @IBAction func shareTextToQZone(sender: UIButton) {
        var content = Content()
        content.description = "QZone Text: Hello World, \(NSUUID().UUIDString)"
        do {
            try MonkeyKing.shareContent(content, serviceProvider: QQServiceProvider(appID: qqAppID, destination: .QZone)) {
                succeed in print(succeed)
            }
        }
        catch let error {
            print(error)
        }
    }

    @IBAction func shareURLToQZone(sender: UIButton) {
        var content = Content()
        content.title = "QZone URL, \(NSUUID().UUIDString)"
        content.description = "soyep.com, \(NSUUID().UUIDString)"
        content.thumbnail = UIImage(named: "rabbit")!
        content.media = .URL(NSURL(string: "http://www.soyep.com")!)
        do {
            try MonkeyKing.shareContent(content, serviceProvider: QQServiceProvider(appID: qqAppID, destination: .QZone)) {
                succeed in print(succeed)
            }
        }
        catch let error {
            print(error)
        }
    }

    @IBAction func shareImageToQZone(sender: UIButton) {
        var content = Content()
        content.title = "QZone URL Image, \(NSUUID().UUIDString)"
        content.description = "Hello World, \(NSUUID().UUIDString)"
        content.thumbnail = nil
        content.media = .Image(UIImage(named: "rabbit")!)
        do {
            try MonkeyKing.shareContent(content, serviceProvider: QQServiceProvider(appID: qqAppID, destination: .QZone)) {
                succeed in print(succeed)
            }
        }
        catch let error {
            print(error)
        }
    }

    @IBAction func shareAudioToQZone(sender: UIButton) {
        var content = Content()
        content.title = "QZone Audio, \(NSUUID().UUIDString)"
        content.description = "Hello World, \(NSUUID().UUIDString)"
        content.thumbnail = UIImage(named: "rabbit")!
        content.media = .Audio(audioURL: NSURL(string: "http://wfmusic.3g.qq.com/s?g_f=0&fr=&aid=mu_detail&id=2511915")!, linkURL: nil)
        do {
            try MonkeyKing.shareContent(content, serviceProvider: QQServiceProvider(appID: qqAppID, destination: .QZone)) {
                succeed in print(succeed)
            }
        }
        catch let error {
            print(error)
        }
    }

    @IBAction func shareVideoToQZone(sender: UIButton) {
        var content = Content()
        content.title = "QZone Video, \(NSUUID().UUIDString)"
        content.description = "Hello World, \(NSUUID().UUIDString)"
        content.thumbnail = UIImage(named: "rabbit")!
        content.media = .Video(NSURL(string: "http://v.youku.com/v_show/id_XOTU2MzA0NzY4.html")!)
        do {
            try MonkeyKing.shareContent(content, serviceProvider: QQServiceProvider(appID: qqAppID, destination: .QZone)) {
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
            try MonkeyKing.OAuth(QQServiceProvider(appID: qqAppID)) {
                (OAuthInfo, response, error) -> Void in

                guard let token = OAuthInfo?["access_token"] as? String, let openID = OAuthInfo?["openid"] as? String else {
                    return
                }

                let query = "get_user_info"
                let userInfoAPI = "https://graph.qq.com/user/\(query)"

                let parameters = ["openid": openID, "access_token": token, "oauth_consumer_key": qqAppID]

                // fetch UserInfo by userInfoAPI
                SimpleNetworking.sharedInstance.request(NSURL(string: userInfoAPI)!, method: .GET, parameters: parameters, completionHandler: {
                    (userInfoDictionary, _, _) -> Void in print("userInfoDictionary \(userInfoDictionary)")
                })

                // More API
                // http://wiki.open.qq.com/wiki/website/API%E5%88%97%E8%A1%A8
            }
        }
        catch let error {
            print(error)
        }
    }
}

