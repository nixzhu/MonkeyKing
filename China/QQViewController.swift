//
//  QQViewController.swift
//  China
//
//  Created by Limon on 15/9/26.
//  Copyright © 2015年 nixWork. All rights reserved.
//

import UIKit
import MonkeyKing

class QQViewController: UIViewController {

    let account = MonkeyKing.Account.qq(appID: Configs.QQ.appID)

    @IBOutlet fileprivate weak var segmentControl: UISegmentedControl!
    
    @IBOutlet weak var fileButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        MonkeyKing.registerAccount(account)
    }

    // MARK: QQ Friends

    @IBAction func shareText(_ sender: UIButton) {

        let info = MonkeyKing.Info(
            title: nil,
            description: "QQ Text: Hello World, \(UUID().uuidString)",
            thumbnail: nil,
            media: nil
        )

        shareInfo(info)
    }

    @IBAction func shareURL(_ sender: UIButton) {

        let info = MonkeyKing.Info(
            title: "QQ URL, \(UUID().uuidString)",
            description: "apple.com/cn, \(UUID().uuidString)",
            thumbnail: UIImage(named: "rabbit")!,
            media: .url(URL(string: "http://www.apple.com/cn")!)
        )

        shareInfo(info)
    }

    @IBAction func shareImage(_ sender: UIButton) {

        let info = MonkeyKing.Info(
            title: "QQ Image, \(UUID().uuidString)",
            description: "Hello World, \(UUID().uuidString)",
            thumbnail: nil,
            media: .image(UIImage(named: "rabbit")!)
        )

        shareInfo(info)
    }

    @IBAction func shareAudio(_ sender: UIButton) {

        let info = MonkeyKing.Info(
            title: "QQ Audio, \(UUID().uuidString)",
            description: "Hello World, \(UUID().uuidString)",
            thumbnail: UIImage(named: "rabbit")!,
            media: .audio(audioURL: URL(string: "http://stream20.qqmusic.qq.com/32464723.mp3")!, linkURL: nil)
        )

        shareInfo(info)
    }

    @IBAction func shareVideo(_ sender: UIButton) {

        let info = MonkeyKing.Info(
            title: "QQ Video, \(UUID().uuidString)",
            description: "Hello World, \(UUID().uuidString)",
            thumbnail: UIImage(named: "rabbit")!,
            media: .video(URL(string: "http://v.youku.com/v_show/id_XOTU2MzA0NzY4.html")!)
        )

        shareInfo(info)
    }

    @IBAction func shareFile(_ sender: AnyObject) {

        do {

            let fileData = try Data(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "pay", ofType: "php")!))

            let info = MonkeyKing.Info(
                title: "Dataline File, \(UUID().uuidString)",
                description: "pay.php",
                thumbnail: nil,
                media: .file(fileData)
            )

            shareInfo(info)
        } catch {
            print(error.localizedDescription)
        }
    }

    @IBAction func segmentChanged(_ sender: AnyObject) {

        fileButton.isHidden = (sender.selectedSegmentIndex != 2)
    }

    fileprivate func shareInfo(_ info: MonkeyKing.Info) {

        var message :MonkeyKing.Message?

        switch self.segmentControl.selectedSegmentIndex{
        case 0:
            message = MonkeyKing.Message.qq(.friends(info: info))
        case 1:
            message = MonkeyKing.Message.qq(.zone(info: info))
        case 2:
            message = MonkeyKing.Message.qq(.dataline(info: info))
        case 3:
            message = MonkeyKing.Message.qq(.favorites(info: info))
        default:
            break
        }

        if let message = message{
            MonkeyKing.deliver(message) { result in
                print("result: \(result)")
            }
        }
    }


    // MARK: OAuth

    @IBAction func OAuth(_ sender: UIButton) {

        // "get_user_info,get_simple_userinfo,add_album,add_idol,add_one_blog,add_pic_t,add_share,add_topic,check_page_fans,del_idol,del_t,get_fanslist,get_idollist,get_info,get_other_info,get_repost_list,list_album,upload_pic,get_vip_info,get_vip_rich_info,get_intimate_friends_weibo,match_nick_tips_weibo"

        MonkeyKing.oauth(for: .qq, scope: "get_user_info") { (info, response, error) in

            print(info)
            
            guard
                let token = info?["access_token"] as? String,
                let openID = info?["openid"] as? String else {
                    return
            }

            let query = "get_user_info"
            let userInfoAPI = "https://graph.qq.com/user/\(query)"

            let parameters = [
                "openid": openID,
                "access_token": token,
                "oauth_consumer_key": Configs.QQ.appID
            ]

            // fetch UserInfo by userInfoAPI
            SimpleNetworking.sharedInstance.request(userInfoAPI, method: .get, parameters: parameters) { (userInfo, _, _) in
                print("userInfo \(userInfo)")
            }

            // More API
            // http://wiki.open.qq.com/wiki/website/API%E5%88%97%E8%A1%A8
        }
    }
}

