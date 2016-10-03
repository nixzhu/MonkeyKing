//
//  WeChatViewController.swift
//  China
//
//  Created by Limon on 15/9/26.
//  Copyright © 2015年 nixWork. All rights reserved.
//

import UIKit
import MonkeyKing

class WeChatViewController: UIViewController {
    
    @IBOutlet fileprivate var segmentControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Should not register account here
        let account = MonkeyKing.Account.weChat(appID: Configs.Wechat.appID, appKey: Configs.Wechat.appKey)
        MonkeyKing.registerAccount(account)
    }

    @IBAction func shareText(_ sender: UIButton) {

        let info = MonkeyKing.Info(
            title: "Timeline Text, \(UUID().uuidString)",
            description: nil,
            thumbnail: nil,
            media: nil
        )

        self.shareInfo(info)
    }

    @IBAction func shareURL(_ sender: UIButton) {

        let info = MonkeyKing.Info(
            title: "Timeline URL, \(UUID().uuidString)",
            description: "Description URL, \(UUID().uuidString)",
            thumbnail: UIImage(named: "rabbit"),
            media: .url(URL(string: "http://soyep.com")!)
        )

        self.shareInfo(info)
    }

    @IBAction func shareImage(_ sender: UIButton) {

        let info = MonkeyKing.Info(
            title: nil,
            description: nil,
            thumbnail: UIImage(named: "rabbit"),
            media: .image(UIImage(named: "rabbit")!)
        )

        self.shareInfo(info)
    }

    @IBAction func shareMusic(_ sender: UIButton) {

        let info = MonkeyKing.Info(
            title: "Timeline Music, \(UUID().uuidString)",
            description: "Description Music, \(UUID().uuidString)",
            thumbnail: UIImage(named: "rabbit"),
            media: .audio(audioURL: URL(string: "http://stream20.qqmusic.qq.com/32464723.mp3")!, linkURL: URL(string: "http://soyep.com")!)
        )

        self.shareInfo(info)
    }

    @IBAction func shareVideo(_ sender: UIButton) {

        let info = MonkeyKing.Info(
            title: "Timeline Video, \(UUID().uuidString)",
            description: "Description Video, \(UUID().uuidString)",
            thumbnail: UIImage(named: "rabbit"),
            media: .video(URL(string: "http://v.youku.com/v_show/id_XNTUxNDY1NDY4.html")!)
        )

        self.shareInfo(info)
    }
    
    fileprivate func shareInfo(_ info: MonkeyKing.Info) {

        var message :MonkeyKing.Message?

        switch self.segmentControl.selectedSegmentIndex{
        case 0:
            message = MonkeyKing.Message.weChat(.session(info: info))
        case 1:
            message = MonkeyKing.Message.weChat(.timeline(info: info))
        case 2:
            message = MonkeyKing.Message.weChat(.favorite(info: info))
        default:
            break
        }

        if let message = message{
            MonkeyKing.deliver(message) { result in
                print("result: \(result)")
            }
        }
    }
}

// MARK: - OAuth

extension WeChatViewController {

    @IBAction func OAuth(_ sender: UIButton) {

        MonkeyKing.oauth(for: .weChat) { [weak self] (dictionary, response, error) in
            self?.fetchUserInfo(dictionary)
            print("error \(error)")
        }
    }

    @IBAction func OAuthWithoutAppKey(_ sender: UIButton) {

        // Should not register account here
        let accountWithoutAppKey = MonkeyKing.Account.weChat(appID: Configs.Wechat.appID, appKey: nil)
        MonkeyKing.registerAccount(accountWithoutAppKey)

        MonkeyKing.oauth(for: .weChat) { (dictionary, response, error) in

            // You can use this code to OAuth, if you do not want to keep the weChatAppKey in client.
            print("dictionary \(dictionary)")
            print("error \(error)")
        }
    }
}

// MARK: - Pay

extension WeChatViewController {

    @IBAction func pay(_ sender: UIButton) {

        do {
            let data = try NSURLConnection.sendSynchronousRequest(URLRequest(url: URL(string: "http://www.example.com/pay.php?payType=weixin")!), returning: nil)
            let urlString = String(data: data, encoding: .utf8)

            let order = MonkeyKing.Order.weChat(urlString: urlString!)

            MonkeyKing.deliver(order) { result in
                print("result: \(result)")
            }

        } catch {
            print(error)
        }
    }
}

// MARK: - Helper

extension WeChatViewController {

    fileprivate func fetchUserInfo(_ oauthInfo: [String: Any]?) {

        guard
            let token = oauthInfo?["access_token"] as? String,
            let openID = oauthInfo?["openid"] as? String,
            let refreshToken = oauthInfo?["refresh_token"] as? String,
            let expiresIn = oauthInfo?["expires_in"] as? Int else {
                return
        }

        let userInfoAPI = "https://api.weixin.qq.com/sns/userinfo"

        let parameters = [
            "openid": openID,
            "access_token": token
        ]

        // fetch UserInfo by userInfoAPI
        SimpleNetworking.sharedInstance.request(userInfoAPI, method: .get, parameters: parameters, completionHandler: { (userInfo, _, _) in

            guard var userInfo = userInfo else {
                return
            }

            userInfo["access_token"] = token
            userInfo["openid"] = openID
            userInfo["refresh_token"] = refreshToken
            userInfo["expires_in"] = expiresIn

            print("userInfo \(userInfo)")
        })

        // More API
        // http://mp.weixin.qq.com/wiki/home/index.html
    }

    fileprivate func fetchWeChatOAuthInfoByCode(code: String) {

        let appID = ""
        let appKey = "" // fetch appKey from server

        var accessTokenAPI = "https://api.weixin.qq.com/sns/oauth2/access_token?"
        accessTokenAPI += "appid=" + appID
        accessTokenAPI += "&secret=" + appKey
        accessTokenAPI += "&code=" + code + "&grant_type=authorization_code"
        
        // OAuth
        SimpleNetworking.sharedInstance.request(accessTokenAPI, method: .get) { (OAuthJSON, response, error) in
            print("OAuthJSON \(OAuthJSON)")
        }
    }

}
