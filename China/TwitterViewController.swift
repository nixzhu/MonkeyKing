
import MonkeyKing
import UIKit

class TwitterViewController: UIViewController {

    let account = MonkeyKing.Account.twitter(appID: Configs.Twitter.appID, appKey: Configs.Twitter.appKey, redirectURL: Configs.Twitter.redirectURL)
    var accessToken: String?
    var accessTokenSecret: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        MonkeyKing.registerAccount(account)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        MonkeyKing.oauth(for: .twitter) { [weak self] info, _, error in
            if let accessToken = info?["oauth_token"] as? String,
                let accessTokenSecret = info?["oauth_token_secret"] as? String {
                self?.accessToken = accessToken
                self?.accessTokenSecret = accessTokenSecret
            }
            print("MonkeyKing.oauth info: \(String(describing: info)), error: \(String(describing: error))")
        }
    }

    @IBAction func shareText(_ sender: UIButton) {
        let message = MonkeyKing.Message.twitter(.default(info: (
            title: nil,
            description: "Text test",
            thumbnail: nil,
            media: nil
        ), mediaIDs: nil, accessToken: accessToken, accessTokenSecret: accessTokenSecret))
        MonkeyKing.deliver(message) { result in
            print("result: \(result)")
        }
    }

    @IBAction func shareImage(_ sender: UIButton) {
        let message = MonkeyKing.Message.twitter(.default(info: (
            title: "Image",
            description: "Rabbit",
            thumbnail: nil,
            media: .image(UIImage(named: "rabbit")!)
        ), mediaIDs: nil, accessToken: accessToken, accessTokenSecret: accessTokenSecret))
        var mediaIDs = [String]()
        DispatchQueue.global(qos: .userInitiated).async {
            let uploadMediaGroup = DispatchGroup()
            uploadMediaGroup.enter()
            MonkeyKing.deliver(message) { result in
                if case .success(let reponse) = result,
                    let json = reponse,
                    let mediaIDString = json["media_id_string"] as? String {
                    mediaIDs.append(mediaIDString)
                    print("Successfully upload media to twitter. Media ID:\(mediaIDString)")
                }
                uploadMediaGroup.leave()
            }
            uploadMediaGroup.wait()
            DispatchQueue.main.sync {
                guard mediaIDs.count > 0 else {
                    print("Failed to upload media to Twitter.")
                    return
                }
                let mediaMessage = MonkeyKing.Message.twitter(.default(info: (
                    title: "Image From MoneyKing",
                    description: nil,
                    thumbnail: nil,
                    media: nil
                ), mediaIDs: mediaIDs, accessToken: self.accessToken, accessTokenSecret: self.accessTokenSecret))
                MonkeyKing.deliver(mediaMessage) { result in
                    print(result)
                }
            }
        }
    }

    // MARK: OAuth

    @IBAction func OAuth(_ sender: UIButton) {
        MonkeyKing.oauth(for: .twitter) { [weak self] info, _, error in
            if let accessToken = info?["oauth_token"] as? String,
                let accessTokenSecret = info?["oauth_token_secret"] as? String {
                self?.accessToken = accessToken
                self?.accessTokenSecret = accessTokenSecret
            }
            print("MonkeyKing.oauth info: \(String(describing: info)), error: \(String(describing: error))")
        }
    }
}
