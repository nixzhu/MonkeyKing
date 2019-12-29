
import MonkeyKing
import UIKit

class WeChatViewController: UIViewController {

    @IBOutlet private var segmentControl: UISegmentedControl!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Should not register account here
        let account = MonkeyKing.Account.weChat(appID: Configs.WeChat.appID, appKey: Configs.WeChat.appKey, miniAppID: Configs.WeChat.miniAppID)
        MonkeyKing.registerAccount(account)
    }

    @IBAction func shareText(_ sender: UIButton) {
        let info = MonkeyKing.Info(
            title: "Text, \(UUID().uuidString)",
            description: nil,
            thumbnail: nil,
            media: nil
        )
        shareInfo(info)
    }

    @IBAction func shareURL(_ sender: UIButton) {
        let info = MonkeyKing.Info(
            title: "URL, \(UUID().uuidString)",
            description: "Description URL, \(UUID().uuidString)",
            thumbnail: UIImage(named: "rabbit"),
            media: .url(URL(string: "http://soyep.com")!)
        )
        shareInfo(info)
    }

    @IBAction func shareImage(_ sender: UIButton) {
        let info = MonkeyKing.Info(
            title: nil,
            description: nil,
            thumbnail: UIImage(named: "rabbit"),
            media: .image(UIImage(named: "rabbit")!)
        )
        shareInfo(info)
    }

    @IBAction func shareGIF(_ sender: UIButton) {

        let url = Bundle.main.url(forResource: "gif", withExtension: "gif")!
        let data = try! Data(contentsOf: url)

        let info = MonkeyKing.Info(
            title: nil,
            description: nil,
            thumbnail: UIImage(data: data)!,
            media: .gif(data)
        )
        shareInfo(info)
    }

    @IBAction func shareMusic(_ sender: UIButton) {
        let info = MonkeyKing.Info(
            title: "Music, \(UUID().uuidString)",
            description: "Description Music, \(UUID().uuidString)",
            thumbnail: UIImage(named: "rabbit"),
            media: .audio(audioURL: URL(string: "http://stream20.qqmusic.qq.com/32464723.mp3")!, linkURL: URL(string: "http://soyep.com")!)
        )
        shareInfo(info)
    }

    @IBAction func shareVideo(_ sender: UIButton) {
        let info = MonkeyKing.Info(
            title: "Video, \(UUID().uuidString)",
            description: "Description Video, \(UUID().uuidString)",
            thumbnail: UIImage(named: "rabbit"),
            media: .video(URL(string: "http://v.youku.com/v_show/id_XNTUxNDY1NDY4.html")!)
        )
        shareInfo(info)
    }

    @IBAction func shareMiniApp(_ sender: UIButton) {
        let info = MonkeyKing.Info(
            title: "Mini App, \(UUID().uuidString)",
            description: nil,
            thumbnail: UIImage(named: "rabbit"),
            media: .miniApp(url: URL(string: "http://soyep.com")!, path: "", withShareTicket: true, type: .release)
        )
        shareInfo(info)
    }

    @IBAction func shareFile(_ sender: UIButton) {
        do {
            let fileData = try Data(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "gif", ofType: "gif")!))
            let info = MonkeyKing.Info(
                title: "File, \(UUID().uuidString)",
                description: "Description File, \(UUID().uuidString)",
                thumbnail: nil,
                media: .file(fileData, fileExt: "gif")
            )
            shareInfo(info)
        } catch {
            print(error.localizedDescription)
        }
    }

    private func shareInfo(_ info: MonkeyKing.Info) {
        var message: MonkeyKing.Message?
        switch segmentControl.selectedSegmentIndex {
        case 0:
            message = MonkeyKing.Message.weChat(.session(info: info))
        case 1:
            message = MonkeyKing.Message.weChat(.timeline(info: info))
        case 2:
            message = MonkeyKing.Message.weChat(.favorite(info: info))
        default:
            break
        }
        if let message = message {
            MonkeyKing.deliver(message) { result in
                print("result: \(result)")
            }
        }
    }
}

// MARK: - Launch Mini App

extension WeChatViewController {
    @IBAction func launchMiniApp(_ sender: UIButton) {
        MonkeyKing.launch(.weChat(.miniApp(username: Configs.WeChat.miniAppID, path: nil, type: .test))) { result in
            print("result: \(result)")
        }
    }
}

// MARK: - OAuth

extension WeChatViewController {

    @IBAction func OAuth(_ sender: UIButton) {
        MonkeyKing.oauth(for: .weChat) { [weak self] result in
            switch result {
            case .success(let dictionary):
                self?.fetchUserInfo(dictionary)
            case .failure(let error):
                print("error \(String(describing: error))")
            }
        }
    }

    @IBAction func OAuthWithoutAppKey(_ sender: UIButton) {
        // Should not register account here
        let accountWithoutAppKey = MonkeyKing.Account.weChat(appID: Configs.WeChat.appID, appKey: nil, miniAppID: nil)
        MonkeyKing.registerAccount(accountWithoutAppKey)

        MonkeyKing.oauth(for: .weChat) { result in
            // You can use this code to OAuth, if you do not want to keep the weChatAppKey in client.
            switch result {
            case .success(let dictionary):
                print("dictionary \(String(describing: dictionary))")
            case .failure(let error):
                print("error \(String(describing: error))")
            }
        }
    }

    @IBAction func OAuthForCode(_ sender: UIButton) {
        MonkeyKing.weChatOAuthForCode { [weak self] result in
            switch result {
            case .success(let code):
                self?.fetchWeChatOAuthInfoByCode(code: code)
            case .failure(let error):
                print("error \(String(describing: error))")
            }
        }
    }
}

// MARK: - Pay

extension WeChatViewController {

    @IBAction func pay(_ sender: UIButton) {
        do {
            let data = try NSURLConnection.sendSynchronousRequest(URLRequest(url: URL(string: "http://www.example.com/pay.php?payType=weixin")!), returning: nil)
            let urlString = String(data: data, encoding: .utf8)!
            let order = MonkeyKing.Order.weChat(urlString: urlString)
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

    private func fetchUserInfo(_ oauthInfo: [String: Any]?) {
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
            "access_token": token,
        ]
        // fetch UserInfo by userInfoAPI
        SimpleNetworking.sharedInstance.request(userInfoAPI, method: .get, parameters: parameters, completionHandler: { userInfo, _, _ in

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

    private func fetchWeChatOAuthInfoByCode(code: String) {
        let appID = Configs.WeChat.appID // fetch appID from server
        let appKey = Configs.WeChat.appKey // fetch appKey from server

        var accessTokenAPI = "https://api.weixin.qq.com/sns/oauth2/access_token?"
        accessTokenAPI += "appid=" + appID
        accessTokenAPI += "&secret=" + appKey
        accessTokenAPI += "&code=" + code + "&grant_type=authorization_code"

        // OAuth
        SimpleNetworking.sharedInstance.request(accessTokenAPI, method: .get) { OAuthJSON, _, _ in
            print("OAuthJSON \(String(describing: OAuthJSON))")
        }
    }
}
