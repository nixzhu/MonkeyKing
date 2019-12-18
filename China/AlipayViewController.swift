
import MonkeyKing
import UIKit

class AlipayViewController: UIViewController {

    @IBOutlet private var segmentedControl: UISegmentedControl!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    private func registerAccount() {
        // Distinguish from authorization
        let account = MonkeyKing.Account.alipay(appID: Configs.Alipay.appID)
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

        let appID = Configs.Alipay.oauthID
        let pid = Configs.Alipay.pid

        let account = MonkeyKing.Account.alipay(appID: appID)
        MonkeyKing.registerAccount(account)

        // ref: https://docs.open.alipay.com/218/105327
        // 获取私钥并将商户信息签名,外部商户可以根据情况存放私钥和签名,只需要遵循RSA签名规范,并将签名字符串base64编码和UrlEncode
        let signType: String = "RSA"
        let sign: String = "RIJ7binMneL9f1OITLXeGfTeDJwgPeZ5Aqk1nPlCHfL1q1hnSUx4x%2BgmmnxDpzJ%2F9K6fzdytkDFlsgcnAUQx2jzAysniUDSFdbKzpacsLXSFJvINUNYowUfR%2FgaY%2FiDV9PICo%2B8Zs4az%2FChoTvxLUbZrFVufSthf2ySBbBNDlck%3D"

        let dic: [String: String] = [
            "apiname": "com.alipay.account.auth",
            "app_id": appID,
            "app_name": "mc",
            "auth_type": "AUTHACCOUNT",
            "biz_type": "openservice",
            "method": "alipay.open.auth.sdk.code.get",
            "pid": pid,
            "product_id": "APP_FAST_LOGIN",
            "scope": "kuaijie",
            "target_id": "\(Int(Date().timeIntervalSince1970 * 1000.0))",
            "sign": sign,
            "sign_type": signType,
        ]

        let keys = dic.keys.sorted { $0 < $1 }

        var array: [String] = []
        for k in keys {
            if let v = dic[k] {
                array.append(k + "=" + v)
            }
        }

        var dataString: String = array.joined(separator: "&")
        dataString += "&sign=\(sign)"
        dataString += "&sign_type=\(signType)"

        MonkeyKing.oauth(for: .alipay, dataString: dataString) { dictionary, _, error in
            print("dictionary \(String(describing: dictionary))")
            print("error \(String(describing: error))")
        }
    }

    @IBAction func certify() {

        // REF: https://docs.open.alipay.com/271/dz10yd

        let urlStr = "https://openapi.alipay.com/gateway.do?alipay_sdk=alipay-sdk-java-dynamicVersionNo&app_id=2015111100758155&biz_content=%7B%22biz_no%22%3A%22ZM201611253000000121200404215172%22%7D&charset=GBK&format=json&method=zhima.customer.certification.certify&return_url=http%3A%2F%2Fwww.taobao.com&sign=MhtfosO8AKbwctDgfGitzLvhbcvi%2FMv3iBES7fRnIXn%2BHcdwq9UWltTs6mEvjk2UoHdLoFrvcSJipiE3sL8kdJMd51t87vcwPCfk7BA5KPwa4%2B1IYzYaK6WwbqOoQB%2FqiJVfni602HiE%2BZAomW7WA3Tjhjy3D%2B9xrLFCipiroDQ%3D&sign_type=RSA2&timestamp=2016-11-25+15%3A00%3A59&version=1.0&sign=MhtfosO8AKbwctDgfGitzLvhbcvi%2FMv3iBES7fRnIXn%2BHcdwq9UWltTs6mEvjk2UoHdLoFrvcSJipiE3sL8kdJMd51t87vcwPCfk7BA5KPwa4%2B1IYzYaK6WwbqOoQB%2FqiJVfni602HiE%2BZAomW7WA3Tjhjy3D%2B9xrLFCipiroDQ%3D"

        var allowedCharacterSet = CharacterSet.urlQueryAllowed
        allowedCharacterSet.remove(charactersIn: "!*'();:@&=+$,%#[]|")

        let encodingURLStr = urlStr.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)!

        let scheme = "alipays://platformapi/startapp?appId=20000067&url=" + encodingURLStr

        MonkeyKing.openScheme(scheme) { url in
            print("callback: \(String(describing: url))")
        }
    }
}

extension Dictionary {

    var toString: String? {
        guard
            let jsonData = try? JSONSerialization.data(withJSONObject: self, options: .prettyPrinted),
            let theJSONText = String(data: jsonData, encoding: .utf8)
        else { return nil }
        return theJSONText
    }
}
