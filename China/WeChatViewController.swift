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
    
    @IBOutlet private var segmentControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Should not register account here
        let account = MonkeyKing.Account.WeChat(appID: Configs.Wechat.appID, appKey: Configs.Wechat.appKey)
        MonkeyKing.registerAccount(account)
    }

    @IBAction func shareText(sender: UIButton) {

        let info = MonkeyKing.Info(
            title: "Timeline Text, \(NSUUID().UUIDString)",
            description: nil,
            thumbnail: nil,
            media: nil
        )

        self.shareInfo(info)
    }

    @IBAction func shareURL(sender: UIButton) {

        let info = MonkeyKing.Info(
            title: "Timeline URL, \(NSUUID().UUIDString)",
            description: "Description URL, \(NSUUID().UUIDString)",
            thumbnail: UIImage(named: "rabbit"),
            media: .URL(NSURL(string: "http://soyep.com")!)
        )

        self.shareInfo(info)
    }

    @IBAction func shareImage(sender: UIButton) {

        let info = MonkeyKing.Info(
            title: nil,
            description: nil,
            thumbnail: UIImage(named: "rabbit"),
            media: .Image(UIImage(named: "rabbit")!)
        )

        self.shareInfo(info)
    }

    @IBAction func shareMusic(sender: UIButton) {

        let info = MonkeyKing.Info(
            title: "Timeline Music, \(NSUUID().UUIDString)",
            description: "Description Music, \(NSUUID().UUIDString)",
            thumbnail: UIImage(named: "rabbit"),
            media: .Audio(audioURL: NSURL(string: "http://stream20.qqmusic.qq.com/32464723.mp3")!, linkURL: NSURL(string: "http://soyep.com")!)
        )

        self.shareInfo(info)
    }

    @IBAction func shareVideo(sender: UIButton) {

        let info = MonkeyKing.Info(
            title: "Timeline Video, \(NSUUID().UUIDString)",
            description: "Description Video, \(NSUUID().UUIDString)",
            thumbnail: UIImage(named: "rabbit"),
            media: .Video(NSURL(string: "http://v.youku.com/v_show/id_XNTUxNDY1NDY4.html")!)
        )

        self.shareInfo(info)
    }
    
    private func shareInfo(info: MonkeyKing.Info) {

        var message :MonkeyKing.Message?

        switch self.segmentControl.selectedSegmentIndex{
        case 0:
            message = MonkeyKing.Message.WeChat(.Session(info: info))
        case 1:
            message = MonkeyKing.Message.WeChat(.Timeline(info: info))
        case 2:
            message = MonkeyKing.Message.WeChat(.Favorite(info: info))
        default:
            break
        }

        if let message = message{
            MonkeyKing.shareMessage(message) { result in
                print("result: \(result)")
            }
        }
    }
}

// MARK: - OAuth

extension WeChatViewController {

    @IBAction func OAuth(sender: UIButton) {

        MonkeyKing.OAuth(.WeChat) { [weak self] (dictionary, response, error) -> Void in
            self?.fetchUserInfo(dictionary)
            print("error \(error)")
        }
    }

    @IBAction func OAuthWithoutAppKey(sender: UIButton) {

        // Should not register account here
        let accountWithoutAppKey = MonkeyKing.Account.WeChat(appID: Configs.Wechat.appID, appKey: nil)
        MonkeyKing.registerAccount(accountWithoutAppKey)

        MonkeyKing.OAuth(.WeChat) { (dictionary, response, error) -> Void in

            // You can use this code to OAuth, if you do not want to keep the weChatAppKey in client.
            print("dictionary \(dictionary)")
            print("error \(error)")
        }
    }
}

// MARK: - Pay

extension WeChatViewController {

    @IBAction func pay(sender: UIButton) {

        do {
            let data = try NSURLConnection.sendSynchronousRequest(NSURLRequest(URL: NSURL(string: "http://www.example.com/pay.php?payType=weixin")!), returningResponse: nil)
            let URLString = String(data: data, encoding: NSUTF8StringEncoding)

            let order = MonkeyKing.Order.WeChat(URLString: URLString!)

            MonkeyKing.payOrder(order) { result in
                print("result: \(result)")
            }

        } catch {
            print(error)
        }
    }
}

// MARK: - Helper

extension WeChatViewController {

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
