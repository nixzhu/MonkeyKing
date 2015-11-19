//
//  QQViewController.swift
//  China
//
//  Created by Limon on 15/9/26.
//  Copyright © 2015年 nixWork. All rights reserved.
//

import UIKit
import MonkeyKing

let qqAppID = "1104965610"
let qqAppKey = "ePNssOYVESuviLWv"

class QQViewController: UIViewController {

    let account = MonkeyKing.Account.QQ(appID: qqAppID)

    override func viewDidLoad() {
        super.viewDidLoad()

        MonkeyKing.registerAccount(account)
    }

    // MARK: QQ Friends

    @IBAction func shareTextToQQ(sender: UIButton) {

        let message = MonkeyKing.Message.QQ(.Friends(info: (
            title: nil,
            description: "QQ Text, hello world",
            thumbnail: nil,
            media: nil
        )))

        MonkeyKing.shareMessage(message) { success in
            print("success: \(success)")
        }
    }

    @IBAction func shareURLToQQ(sender: UIButton) {

        let message = MonkeyKing.Message.QQ(.Friends(info: (
            title: "friends URL",
            description: "apple.com",
            thumbnail: UIImage(named: "rabbit")!,
            media: .URL(NSURL(string: "http://www.apple.com/cn")!)
        )))

        MonkeyKing.shareMessage(message) { success in
            print("success: \(success)")
        }
    }

    @IBAction func shareImageToQQ(sender: UIButton) {

        let message = MonkeyKing.Message.QQ(.Friends(info: (
            title: "friends Image",
            description: "hello world",
            thumbnail: nil,
            media: .Image(UIImage(named: "rabbit")!)
        )))

        MonkeyKing.shareMessage(message) { success in
            print("success: \(success)")
        }
    }

    @IBAction func shareAudioToQQ(sender: UIButton) {

        let message = MonkeyKing.Message.QQ(.Friends(info: (
            title: "friends Audio",
            description: "hello world",
            thumbnail: UIImage(named: "rabbit")!,
            media: .Audio(audioURL: NSURL(string: "http://wfmusic.3g.qq.com/s?g_f=0&fr=&aid=mu_detail&id=2511915")!, linkURL: nil)
        )))

        MonkeyKing.shareMessage(message) { success in
            print("success: \(success)")
        }
    }

    @IBAction func shareVideoToQQ(sender: UIButton) {

        let message = MonkeyKing.Message.QQ(.Friends(info: (
            title: "friends Video",
            description: "hello world",
            thumbnail: UIImage(named: "rabbit")!,
            media: .Video(NSURL(string: "http://v.youku.com/v_show/id_XOTU2MzA0NzY4.html")!)
        )))

        MonkeyKing.shareMessage(message) { success in
            print("success: \(success)")
        }
    }

    // MARK: QZone

    @IBAction func shareTextToQZone(sender: UIButton) {

        let message = MonkeyKing.Message.QQ(.Zone(info: (
            title: nil,
            description: "QZone Text, hello world",
            thumbnail: nil,
            media: nil
        )))

        MonkeyKing.shareMessage(message) { success in
            print("success: \(success)")
        }
    }

    @IBAction func shareURLToQZone(sender: UIButton) {

        let message = MonkeyKing.Message.QQ(.Zone(info: (
            title: "QZone URL",
            description: "apple.com",
            thumbnail: UIImage(named: "rabbit")!,
            media: .URL(NSURL(string: "http://www.qq.com")!)
        )))

        MonkeyKing.shareMessage(message) { success in
            print("success: \(success)")
        }
    }

    @IBAction func shareImageToQZone(sender: UIButton) {

        let message = MonkeyKing.Message.QQ(.Zone(info: (
            title: "QZone URL Image",
            description: "hello world",
            thumbnail: nil,
            media: .Image(UIImage(named: "rabbit")!)
        )))

        MonkeyKing.shareMessage(message) { success in
            print("success: \(success)")
        }
    }

    @IBAction func shareAudioToQZone(sender: UIButton) {

        let message = MonkeyKing.Message.QQ(.Zone(info: (
            title: "QZone Audio",
            description: "hello world",
            thumbnail: nil,
            media: .Audio(audioURL: NSURL(string: "http://wfmusic.3g.qq.com/s?g_f=0&fr=&aid=mu_detail&id=2511915")!, linkURL: nil)
        )))

        MonkeyKing.shareMessage(message) { success in
            print("success: \(success)")
        }
    }

    @IBAction func shareVideoToQZone(sender: UIButton) {

        let message = MonkeyKing.Message.QQ(.Zone(info: (
            title: "QZone Video",
            description: "hello world",
            thumbnail: UIImage(named: "rabbit")!,
            media: .Video(NSURL(string: "http://v.youku.com/v_show/id_XOTU2MzA0NzY4.html")!)
        )))

        MonkeyKing.shareMessage(message) { success in
            print("success: \(success)")
        }
    }

    // MARK: OAuth

    @IBAction func OAuth(sender: UIButton) {

        // "get_user_info,get_simple_userinfo,add_album,add_idol,add_one_blog,add_pic_t,add_share,add_topic,check_page_fans,del_idol,del_t,get_fanslist,get_idollist,get_info,get_other_info,get_repost_list,list_album,upload_pic,get_vip_info,get_vip_rich_info,get_intimate_friends_weibo,match_nick_tips_weibo"

        MonkeyKing.OAuth(account, scope: "get_user_info") { (OAuthInfo, response, error) -> Void in

            guard let token = OAuthInfo?["access_token"] as? String,
                let openID = OAuthInfo?["openid"] as? String else {
                    return
            }

            let scope = "get_user_info"
            let userInfoAPI = "https://graph.qq.com/user/\(scope)"

            let parameters = [
                "openid": openID,
                "access_token": token,
                "oauth_consumer_key": qqAppID
            ]

            print(parameters)

            // fetch UserInfo by userInfoAPI
            SimpleNetworking.sharedInstance.request(NSURL(string: userInfoAPI)!, method: .GET, parameters: parameters, completionHandler: { (userInfoDictionary, _, _) -> Void in
                print("userInfoDictionary \(userInfoDictionary)")
            })

            // More API
            // http://wiki.open.qq.com/wiki/website/API列表
        }
    }
}

