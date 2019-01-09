
import UIKit
import MonkeyKing

class AlipayViewController: UIViewController {
    
    @IBOutlet private var segmentedControl: UISegmentedControl!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    private func registerAccount() {
        // Distinguish from authorization
        let account = MonkeyKing.Account.alipay(appID: Configs.Alipay.appID, pid: nil)
        MonkeyKing.registerAccount(account)
    }

    // MARK: Share

    @IBAction func shareTextToAlipay(_ sender: UIButton) {
        let info = MonkeyKing.Info(
            title: "Friends Text, \(UUID().uuidString)",
            description: nil,
            thumbnail: nil,
            media: nil
        )
        shareInfo(info)
    }

    @IBAction func shareImageToAlipay(_ sender: UIButton) {
        let info = MonkeyKing.Info(
            title: nil,
            description: nil,
            thumbnail: nil,
            media: .image(UIImage(named: "rabbit")!)
        )
        shareInfo(info)
    }

    @IBAction func shareURLToAlipay(_ sender: UIButton) {
        let info = MonkeyKing.Info(
            title: "Friends URL, \(UUID().uuidString)",
            description: "Description URL, \(UUID().uuidString)",
            thumbnail: UIImage(named: "rabbit"),
            media: .url(URL(string: "http://soyep.com")!)
        )
        shareInfo(info)
    }

    private func shareInfo(_ info: MonkeyKing.Info) {

        registerAccount()

        var message: MonkeyKing.Message?
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            message = MonkeyKing.Message.alipay(.friends(info: info))
        case 1:
            guard info.media != nil else {
                print("目前支付宝生活圈还不支持纯文本的分享")
                break
            }
            message = MonkeyKing.Message.alipay(.timeline(info: info))
        default:
            break
        }
        if let message = message {
            MonkeyKing.deliver(message) { result in
                print("result: \(result)")
            }
        }
    }

    // MARK: Pay

    @IBAction func pay(_ sender: UIButton) {
        do {
            registerAccount()
            let data = try NSURLConnection.sendSynchronousRequest(URLRequest(url: URL(string: "https://www.example.com/pay.php?payType=alipay")!), returning: nil)
            let urlString = String(data: data, encoding: .utf8)!
            let order = MonkeyKing.Order.alipay(urlString: urlString)
            MonkeyKing.deliver(order) { result in
                print("result: \(result)")
            }
        } catch {
            print(error)
        }
    }

    // MARK: Oauth

    @IBAction func oauth(_ sender: UIButton) {

        let account = MonkeyKing.Account.alipay(appID: Configs.Alipay.oauthID, pid: Configs.Alipay.pid)
        MonkeyKing.registerAccount(account)

        // ref: https://docs.open.alipay.com/218/105327
        let signType: String = "RSA"
        let sign: String = "RIJ7binMneL9f1OITLXeGfTeDJwgPeZ5Aqk1nPlCHfL1q1hnSUx4x%2BgmmnxDpzJ%2F9K6fzdytkDFlsgcnAUQx2jzAysniUDSFdbKzpacsLXSFJvINUNYowUfR%2FgaY%2FiDV9PICo%2B8Zs4az%2FChoTvxLUbZrFVufSthf2ySBbBNDlck%3D"
        let appUrlScheme: String = "apoauth" + Configs.Alipay.oauthID

        MonkeyKing.oauth(for: .alipay, signType: signType, sign: sign, appUrlScheme: appUrlScheme) { (dictionary, response, error) in
            print("dictionary \(String(describing: dictionary))")
            print("error \(String(describing: error))")
        }

    }
}
