
import UIKit
import MonkeyKing

class WeiboViewController: UIViewController {

    var accessToken: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        let account = MonkeyKing.Account.weibo(appID: Configs.Weibo.appID, appKey: Configs.Weibo.appKey, redirectURL: Configs.Weibo.redirectURL)
        MonkeyKing.registerAccount(account)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // not installed weibo app, must need accessToken
        if !MonkeyKing.SupportedPlatform.weibo.isAppInstalled {
            MonkeyKing.oauth(for: .weibo) { [weak self] (info, response, error) in
                if let accessToken = info?["access_token"] as? String {
                    self?.accessToken = accessToken
                }
                print("MonkeyKing.oauth info: \(String(describing: info)), error: \(String(describing: error))")
            }
        }
    }

    @IBAction func shareImage(_ sender: UIButton) {
        let message = MonkeyKing.Message.weibo(.default(info: (
            title: "Image",
            description: "Rabbit",
            thumbnail: nil,
            media: .image(UIImage(named: "rabbit")!)
        ), accessToken: accessToken))
        MonkeyKing.deliver(message) { result in
            print("result: \(result)")
        }
    }

    @IBAction func shareText(_ sender: UIButton) {
        let message = MonkeyKing.Message.weibo(.default(info: (
            title: nil,
            description: "Text",
            thumbnail: nil,
            media: nil
        ), accessToken: accessToken))
        MonkeyKing.deliver(message) { result in
            print("result: \(result)")
        }
    }

    @IBAction func shareURL(_ sender: UIButton) {
        let message = MonkeyKing.Message.weibo(.default(info: (
            title: "News",
            description: "Hello Yep",
            thumbnail: UIImage(named: "rabbit"),
            media: .url(URL(string: "http://soyep.com")!)
        ), accessToken: accessToken))
        MonkeyKing.deliver(message) { result in
            print("result: \(result)")
        }
    }

    // MARK: OAuth

    @IBAction func OAuth(_ sender: UIButton) {
        MonkeyKing.oauth(for: .weibo) { (info, response, error) in
            // App or Web: token & userID
            guard
                let unwrappedInfo = info,
                let token = (unwrappedInfo["access_token"] as? String) ?? (unwrappedInfo["accessToken"] as? String),
                let userID = (unwrappedInfo["uid"] as? String) ?? (unwrappedInfo["userID"] as? String) else {
                    return
            }
            let userInfoAPI = "https://api.weibo.com/2/users/show.json"
            let parameters = [
                "uid": userID,
                "access_token": token
            ]
            // fetch UserInfo by userInfoAPI
            SimpleNetworking.sharedInstance.request(userInfoAPI, method: .get, parameters: parameters) { (userInfo, _, _) in
                print("userInfo \(String(describing: userInfo))")
            }
            // More API
            // http://open.weibo.com/wiki/%E5%BE%AE%E5%8D%9AAPI
        }
    }
}
