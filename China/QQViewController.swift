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

    let account = MonkeyKing.Account.QQ(appID: qqAppID)

    override func viewDidLoad() {
        super.viewDidLoad()
        MonkeyKing.registerAccount(account)
    }

    // MARK: QQ Friends

    @IBAction func shareImageToQQ(sender: UIButton) {

        let message = MonkeyKing.Message.QQ(.Friends(info: (
            title: "friends",
            description: "helloworld",
            thumbnail: nil,
            media: .Image(UIImage(named: "rabbit")!)
        )))

        MonkeyKing.shareMessage(message) { success in
            print("success: \(success)")
        }
    }

    @IBAction func shareTextToQQ(sender: UIButton) {

        let message = MonkeyKing.Message.QQ(.Friends(info: (
            title: nil,
            description: "helloworld",
            thumbnail: nil,
            media: nil
        )))

        MonkeyKing.shareMessage(message) { success in
            print("success: \(success)")
        }
    }

    @IBAction func shareURLToQQ(sender: UIButton) {

        let message = MonkeyKing.Message.QQ(.Friends(info: (
            title: "friends",
            description: "apple.com",
            thumbnail: UIImage(named: "rabbit")!,
            media: .URL(NSURL(string: "http://www.apple.com/cn")!)
        )))

        MonkeyKing.shareMessage(message) { success in
            print("success: \(success)")
        }

    }

    // MARK: QZone

    @IBAction func shareImageToQZone(sender: UIButton) {

        let message = MonkeyKing.Message.QQ(.Zone(info: (
            title: "friends",
            description: "helloworld",
            thumbnail: nil,
            media: .Image(UIImage(named: "rabbit")!)
        )))

        MonkeyKing.shareMessage(message) { success in
            print("success: \(success)")
        }
    }

    @IBAction func shareTextToQZone(sender: UIButton) {

        let message = MonkeyKing.Message.QQ(.Zone(info: (
            title: nil,
            description: "helloworld",
            thumbnail: nil,
            media: nil
        )))

        MonkeyKing.shareMessage(message) { success in
            print("success: \(success)")
        }
    }

    @IBAction func shareURLToQZone(sender: UIButton) {

        let message = MonkeyKing.Message.QQ(.Zone(info: (
            title: "friends",
            description: "apple.com",
            thumbnail: UIImage(named: "rabbit")!,
            media: .URL(NSURL(string: "http://www.qq.com")!)
        )))

        MonkeyKing.shareMessage(message) { success in
            print("success: \(success)")
        }
    }

    // MARK: OAuth

    @IBAction func OAuth(sender: UIButton) {

        // "get_user_info,get_simple_userinfo,add_album,add_idol,add_one_blog,add_pic_t,add_share,add_topic,check_page_fans,del_idol,del_t,get_fanslist,get_idollist,get_info,get_other_info,get_repost_list,list_album,upload_pic,get_vip_info,get_vip_rich_info,get_intimate_friends_weibo,match_nick_tips_weibo"

        MonkeyKing.OAuth(account, scope: "get_user_info") { (dictionary, response, error) -> Void in

            guard let results = dictionary else {
                return
            }

            let token = results["access_token"] as! String
            let openid = results["openid"] as! String

            let scope = "get_user_info"
            let userInfoAPI = "https://graph.qq.com/user/\(scope)?access_token=\(token)&oauth_consumer_key=\(qqAppID)&openid=\(openid)"

            // You can use this URL to request the info.
            print(userInfoAPI)

            // More API
            // http://wiki.open.qq.com/wiki/website/API列表

            //  带中文的链接，乖乖地复制吧🙂
        }
    }
}

