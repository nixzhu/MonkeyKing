
import Foundation

extension MonkeyKing {

    class func fetchWeChatOAuthInfoByCode(code: String, completionHandler: @escaping OAuthCompletionHandler) {
        var appID = ""
        var appKey = ""
        for case let .weChat(id, key, _) in shared.accountSet {
            guard let key = key else {
                completionHandler(["code": code], nil, nil)
                return
            }
            appID = id
            appKey = key
        }
        var accessTokenAPI = "https://api.weixin.qq.com/sns/oauth2/access_token"
        accessTokenAPI += "?grant_type=authorization_code"
        accessTokenAPI += "&appid=\(appID)"
        accessTokenAPI += "&secret=\(appKey)"
        accessTokenAPI += "&code=\(code)"
        // OAuth
        shared.request(accessTokenAPI, method: .get) { (json, response, error) in
            completionHandler(json, response, error)
        }
    }

    class func createAlipayMessageDictionary(withScene scene: NSNumber, info: Info, appID: String) -> [String: Any] {
        enum AlipayMessageType {
            case text
            case image(UIImage)
            case imageData(Data)
            case url(URL)
        }
        let keyUID = "CF$UID"
        let keyClass = "$class"
        let keyClasses = "$classes"
        let keyClassname = "$classname"
        var messageType: AlipayMessageType = .text
        if let media = info.media {
            switch media {
            case .url(let url):
                messageType = .url(url)
            case .image(let image):
                messageType = .image(image)
            case .imageData(let imageData):
                messageType = .imageData(imageData)
            case .gif:
                fatalError("Alipay not supports GIF type")
            case .audio:
                fatalError("Alipay not supports Audio type")
            case .video:
                fatalError("Alipay not supports Video type")
            case .file:
                fatalError("Alipay not supports File type")
            case .miniApp:
                fatalError("Alipay not supports Mini App type")
            }
        } else { // Text
            messageType = .text
        }
        // Public Items
        let UIDValue: Int
        let APMediaType: String
        switch messageType {
        case .text:
            UIDValue = 20
            APMediaType = "APShareTextObject"
        case .image, .imageData:
            UIDValue = 21
            APMediaType = "APShareImageObject"
        case .url:
            UIDValue = 24
            APMediaType = "APShareWebObject"
        }
        let publicObjectsItem0 = "$null"
        let publicObjectsItem1: [String: Any] = [
            keyClass: [keyUID: UIDValue],
            "NS.keys": [
                [keyUID: 2],
                [keyUID: 3]
            ],
            "NS.objects": [
                [keyUID: 4],
                [keyUID: 11]
            ]
        ]
        let publicObjectsItem2 = "app"
        let publicObjectsItem3 = "req"
        let publicObjectsItem4: [String: Any] = [
            keyClass: [keyUID: 10],
            "appKey": [keyUID: 6],
            "bundleId": [keyUID: 7],
            "name": [keyUID: 5],
            "scheme": [keyUID: 8],
            "sdkVersion": [keyUID: 9]
        ]
        let publicObjectsItem5 = Bundle.main.monkeyking_displayName ?? "China"
        let publicObjectsItem6 = appID
        let publicObjectsItem7 = Bundle.main.monkeyking_bundleID ?? "com.nixWork.China"
        let publicObjectsItem8 = "ap\(appID)"
        let publicObjectsItem9 = "1.1.0.151016" // SDK Version
        let publicObjectsItem10: [String: Any] = [
            keyClasses: ["APSdkApp", "NSObject"],
            keyClassname: "APSdkApp"
        ]
        let publicObjectsItem11: [String: Any] = [
            keyClass: [keyUID: UIDValue - 1],
            "message": [keyUID: 13],
            "scene": [keyUID: UIDValue - 2],
            "type": [keyUID: 12]
        ]
        let publicObjectsItem12: NSNumber = 0
        let publicObjectsItem13: [String: Any] = [      // For Text(13) && Image(13)
            keyClass: [keyUID: UIDValue - 3],
            "mediaObject": [keyUID: 14]
        ]
        let publicObjectsItem14: [String: Any] = [      // For Image(16) && URL(17)
            keyClasses: ["NSMutableData", "NSData", "NSObject"],
            keyClassname: "NSMutableData"
        ]
        let publicObjectsItem16: [String: Any] = [
            keyClasses: [APMediaType, "NSObject"],
            keyClassname: APMediaType
        ]
        let publicObjectsItem17: [String: Any] = [
            keyClasses: ["APMediaMessage", "NSObject"],
            keyClassname: "APMediaMessage"
        ]
        let publicObjectsItem18: NSNumber = scene
        let publicObjectsItem19: [String: Any] = [
            keyClasses: ["APSendMessageToAPReq", "APBaseReq", "NSObject"],
            keyClassname: "APSendMessageToAPReq"
        ]
        let publicObjectsItem20: [String: Any] = [
            keyClasses: ["NSMutableDictionary", "NSDictionary", "NSObject"],
            keyClassname: "NSMutableDictionary"
        ]
        var objectsValue: [Any] = [
            publicObjectsItem0, publicObjectsItem1, publicObjectsItem2, publicObjectsItem3,
            publicObjectsItem4, publicObjectsItem5, publicObjectsItem6, publicObjectsItem7,
            publicObjectsItem8, publicObjectsItem9, publicObjectsItem10, publicObjectsItem11,
            publicObjectsItem12
        ]
        switch messageType {
        case .text:
            let textObjectsItem14: [String: Any] = [
                keyClass: [keyUID: 16],
                "text": [keyUID: 15]
            ]
            let textObjectsItem15 = info.title ?? "Input Text"
            objectsValue = objectsValue + [publicObjectsItem13, textObjectsItem14, textObjectsItem15]
        case .image(let image):
            let imageObjectsItem14: [String: Any] = [
                keyClass: [keyUID: 17],
                "imageData": [keyUID: 15]
            ]
            let imageData = image.jpegData(compressionQuality: 0.9) ?? Data()
            let imageObjectsItem15: [String: Any] = [
                keyClass: [keyUID: 16],
                "NS.data": imageData
            ]
            objectsValue = objectsValue + [publicObjectsItem13, imageObjectsItem14, imageObjectsItem15, publicObjectsItem14]
        case .imageData(let imageData):
            let imageObjectsItem14: [String: Any] = [
                keyClass: [keyUID: 17],
                "imageData": [keyUID: 15]
            ]
            let imageObjectsItem15: [String: Any] = [
                keyClass: [keyUID: 16],
                "NS.data": imageData
            ]
            objectsValue = objectsValue + [publicObjectsItem13, imageObjectsItem14, imageObjectsItem15, publicObjectsItem14]
        case .url(let url):
            let urlObjectsItem13: [String: Any] = [
                keyClass: [keyUID: 21],
                "desc": [keyUID: 15],
                "mediaObject": [keyUID: 18],
                "thumbData": [keyUID: 16],
                "title": [keyUID: 14]
            ]
            let thumbnailData = info.thumbnail?.monkeyking_compressedImageData ?? Data()
            let urlObjectsItem14 = info.title ?? "Input Title"
            let urlObjectsItem15 = info.description ?? "Input Description"
            let urlObjectsItem16: [String: Any] = [
                keyClass: [keyUID: 17],
                "NS.data": thumbnailData
            ]
            let urlObjectsItem18: [String: Any] = [
                keyClass: [keyUID: 20],
                "webpageUrl": [keyUID: 19]
            ]
            let urlObjectsItem19 = url.absoluteString
            objectsValue = objectsValue + [
                urlObjectsItem13,
                urlObjectsItem14,
                urlObjectsItem15,
                urlObjectsItem16,
                publicObjectsItem14,
                urlObjectsItem18,
                urlObjectsItem19
            ]
        }
        objectsValue += [publicObjectsItem16, publicObjectsItem17, publicObjectsItem18, publicObjectsItem19, publicObjectsItem20]
        let dictionary: [String: Any] = [
            "$archiver": "NSKeyedArchiver",
            "$objects": objectsValue,
            "$top": ["root" : [keyUID: 1]],
            "$version": 100000
        ]
        return dictionary
    }

    func request(_ urlString: String, method: Networking.Method, parameters: [String: Any]? = nil, encoding: Networking.ParameterEncoding = .url, headers: [String: String]? = nil, completionHandler: @escaping Networking.NetworkingResponseHandler) {
        Networking.shared.request(urlString, method: method, parameters: parameters, encoding: encoding, headers: headers, completionHandler: completionHandler)
    }

    func upload(_ urlString: String, parameters: [String: Any], headers: [String: String]? = nil,completionHandler: @escaping Networking.NetworkingResponseHandler) {
        Networking.shared.upload(urlString, parameters: parameters, headers: headers, completionHandler: completionHandler)
    }

    class func openURL(urlString: String, options: [UIApplication.OpenExternalURLOptionsKey: Any] = [:], completionHandler completion: ((Bool) -> Swift.Void)? = nil) {
        guard let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) else {
            completion?(false)
            return
        }
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: options) { flag in
                completion?(flag)
            }
        } else {
            completion?(UIApplication.shared.openURL(url))
        }
    }

    class func openURL(urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        return UIApplication.shared.openURL(url)
    }

    func canOpenURL(urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
}
