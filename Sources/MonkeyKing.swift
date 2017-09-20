//
//  MonkeyKing.swift
//  MonkeyKing
//
//  Created by NIX on 15/9/11.
//  Copyright © 2015年 nixWork. All rights reserved.
//

import UIKit
import WebKit

open class MonkeyKing: NSObject {

    public enum DeliverResult {
        case success(ResponseJSON?)
        case failure(Error)
    }
    public typealias ResponseJSON = [String: Any]
    public typealias DeliverCompletionHandler = (_ result: DeliverResult) -> Void
    public typealias OAuthCompletionHandler = (_ info: [String: Any]?, _ response: URLResponse?, _ error: Swift.Error?) -> Void
    public typealias PayCompletionHandler = (_ result: Bool) -> Void

    static let sharedMonkeyKing = MonkeyKing()

    var accountSet = Set<Account>()

    var oauthCompletionHandler: OAuthCompletionHandler?
    fileprivate var deliverCompletionHandler: DeliverCompletionHandler?
    fileprivate var payCompletionHandler: PayCompletionHandler?
    fileprivate var customAlipayOrderScheme: String?

    var webView: WKWebView?

    fileprivate override init() {}

    public enum Account: Hashable {
        case weChat(appID: String, appKey: String?)
        case qq(appID: String)
        case weibo(appID: String, appKey: String, redirectURL: String)
        case pocket(appID: String)
        case alipay(appID: String)
        case twitter(appID: String, appKey: String, redirectURL: String)

        public var isAppInstalled: Bool {
            switch self {
            case .weChat:
                return MonkeyKing.SupportedPlatform.weChat.isAppInstalled
            case .qq:
                return MonkeyKing.SupportedPlatform.qq.isAppInstalled
            case .weibo:
                return MonkeyKing.SupportedPlatform.weibo.isAppInstalled
            case .pocket:
                return MonkeyKing.SupportedPlatform.pocket.isAppInstalled
            case .alipay:
                return MonkeyKing.SupportedPlatform.alipay.isAppInstalled
            case .twitter:
                return MonkeyKing.SupportedPlatform.twitter.isAppInstalled
            }
        }

        public var appID: String {
            switch self {
            case .weChat(let appID, _):
                return appID
            case .qq(let appID):
                return appID
            case .weibo(let appID, _, _):
                return appID
            case .pocket(let appID):
                return appID
            case .alipay(let appID):
                return appID
            case .twitter(let appID, _, _):
                return appID
            }
        }

        public var hashValue: Int {
            return appID.hashValue
        }

        public var canWebOAuth: Bool {
            switch self {
            case .qq, .weibo, .pocket, .weChat, .twitter:
                return true
            default:
                return false
            }
        }

        public static func ==(lhs: MonkeyKing.Account, rhs: MonkeyKing.Account) -> Bool {
            return lhs.appID == rhs.appID
        }
    }

    public enum SupportedPlatform {
        case qq
        case weChat
        case weibo
        case pocket
        case alipay
        case twitter

        public var isAppInstalled: Bool {
            switch self {
            case .weChat:
                return sharedMonkeyKing.canOpenURL(urlString: "weixin://")
            case .qq:
                return sharedMonkeyKing.canOpenURL(urlString: "mqqapi://")
            case .weibo:
                return sharedMonkeyKing.canOpenURL(urlString: "weibosdk://request")
            case .pocket:
                return sharedMonkeyKing.canOpenURL(urlString: "pocket-oauth-v1://")
            case .alipay:
                return sharedMonkeyKing.canOpenURL(urlString: "alipayshare://")
            case .twitter:
                return sharedMonkeyKing.canOpenURL(urlString: "twitter://")
            }
        }
    }

    open class func registerAccount(_ account: Account) {
        guard account.isAppInstalled || account.canWebOAuth else { return }
        for oldAccount in MonkeyKing.sharedMonkeyKing.accountSet {
            switch oldAccount {
            case .weChat:
                if case .weChat = account { sharedMonkeyKing.accountSet.remove(oldAccount) }
            case .qq:
                if case .qq = account { sharedMonkeyKing.accountSet.remove(oldAccount) }
            case .weibo:
                if case .weibo = account { sharedMonkeyKing.accountSet.remove(oldAccount) }
            case .pocket:
                if case .pocket = account { sharedMonkeyKing.accountSet.remove(oldAccount) }
            case .alipay:
                if case .alipay = account { sharedMonkeyKing.accountSet.remove(oldAccount) }
            case .twitter:
                if case .twitter = account { sharedMonkeyKing.accountSet.remove(oldAccount) }
            }
        }
        sharedMonkeyKing.accountSet.insert(account)
    }
}


// MARK: OpenURL Handler

extension MonkeyKing {

    public class func handleOpenURL(_ url: URL) -> Bool {
        guard let urlScheme = url.scheme else { return false }
        // WeChat
        if urlScheme.hasPrefix("wx") {
            let urlString = url.absoluteString
            // OAuth
            if urlString.contains("state=Weixinauth") {
                let queryDictionary = url.monkeyking_queryDictionary
                guard let code = queryDictionary["code"] as? String else { return false }
                // Login Succcess
                fetchWeChatOAuthInfoByCode(code: code) { (info, response, error) in
                    sharedMonkeyKing.oauthCompletionHandler?(info, response, error)
                }
                return true
            }
            // SMS OAuth
            if urlString.contains("wapoauth") {
                let queryDictionary = url.monkeyking_queryDictionary
                guard let m = queryDictionary["m"] as? String else { return false }
                guard let t = queryDictionary["t"] as? String else { return false }
                guard let account = sharedMonkeyKing.accountSet[.weChat] else { return false }
                let appID = account.appID
                let urlString = "https://open.weixin.qq.com/connect/smsauthorize?appid=\(appID)&redirect_uri=\(appID)%3A%2F%2Foauth&response_type=code&scope=snsapi_message,snsapi_userinfo,snsapi_friend,snsapi_contact&state=xxx&uid=1926559385&m=\(m)&t=\(t)"
                addWebView(withURLString: urlString)
                return true
            }
            // Pay
            if urlString.contains("://pay/") {
                var result = false
                defer {
                    sharedMonkeyKing.payCompletionHandler?(result)
                }
                let queryDictionary = url.monkeyking_queryDictionary
                guard let ret = queryDictionary["ret"] as? String else { return false }
                result = (ret == "0")
                return result
            }
            // Share
            if let data = UIPasteboard.general.data(forPasteboardType: "content") {
                if let dict = try? PropertyListSerialization.propertyList(from: data, options: PropertyListSerialization.MutabilityOptions(), format: nil) as? [String: Any] {
                    guard
                        let account = sharedMonkeyKing.accountSet[.weChat],
                        let info = dict?[account.appID] as? [String: Any],
                        let result = info["result"] as? String,
                        let resultCode = Int(result) else {
                            return false
                    }
                    let success = (resultCode == 0)
                    if success {
                        sharedMonkeyKing.deliverCompletionHandler?(.success(nil))
                    } else {
                        sharedMonkeyKing.deliverCompletionHandler?(.failure(.sdk(reason: .unknown))) // TODO: pass resultCode
                    }
                    return success
                }
            }
            // OAuth Failed
            if urlString.contains("platformId=wechat") && !urlString.contains("state=Weixinauth") {
                let error = NSError(domain: "WeChat OAuth Error", code: -1, userInfo: nil)
                sharedMonkeyKing.oauthCompletionHandler?(nil, nil, error)
                return false
            }
            return false
        }
        // QQ Share
        if urlScheme.hasPrefix("QQ") {
            guard let errorDescription = url.monkeyking_queryDictionary["error"] as? String else { return false }
            let success = (errorDescription == "0")
            if success {
                sharedMonkeyKing.deliverCompletionHandler?(.success(nil))
            } else {
                sharedMonkeyKing.deliverCompletionHandler?(.failure(.sdk(reason: .unknown))) // TODO: pass errorDescription
            }
            return success
        }
        // QQ OAuth
        if urlScheme.hasPrefix("tencent") {
            guard let account = sharedMonkeyKing.accountSet[.qq] else { return false }
            var userInfo: [String: Any]?
            var error: Swift.Error?
            defer {
                sharedMonkeyKing.oauthCompletionHandler?(userInfo, nil, error)
            }
            guard
                let data = UIPasteboard.general.data(forPasteboardType: "com.tencent.tencent\(account.appID)"),
                let info = NSKeyedUnarchiver.unarchiveObject(with: data) as? [String: Any] else {
                    error = NSError(domain: "OAuth Error", code: -1, userInfo: nil)
                    return false
            }
            guard let result = info["ret"] as? Int, result == 0 else {
                if let errorDomatin = info["user_cancelled"] as? String, errorDomatin == "YES" {
                    error = NSError(domain: "User Cancelled", code: -2, userInfo: nil)
                } else {
                    error = NSError(domain: "OAuth Error", code: -1, userInfo: nil)
                }
                return false
            }
            userInfo = info
            return true
        }
        // Weibo
        if urlScheme.hasPrefix("wb") {
            let items = UIPasteboard.general.items
            var results = [String: Any]()
            for item in items {
                for (key, value) in item {
                    if let valueData = value as? Data, key == "transferObject" {
                        results[key] = NSKeyedUnarchiver.unarchiveObject(with: valueData)
                    }
                }
            }
            guard
                let responseInfo = results["transferObject"] as? [String: Any],
                let type = responseInfo["__class"] as? String else {
                    return false
            }
            guard let statusCode = responseInfo["statusCode"] as? Int else {
                return false
            }
            switch type {
            // OAuth
            case "WBAuthorizeResponse":
                var userInfo: [String: Any]?
                var error: Swift.Error?
                defer {
                    sharedMonkeyKing.oauthCompletionHandler?(responseInfo, nil, error)
                }
                userInfo = responseInfo
                if statusCode != 0 {
                    error = NSError(domain: "OAuth Error", code: -1, userInfo: userInfo)
                    return false
                }
                return true
            // Share
            case "WBSendMessageToWeiboResponse":
                let success = (statusCode == 0)
                if success {
                    sharedMonkeyKing.deliverCompletionHandler?(.success(nil))
                } else {
                    sharedMonkeyKing.deliverCompletionHandler?(.failure(.sdk(reason: .unknown)))
                }
                return success
            default:
                break
            }
        }
        // Pocket OAuth
        if urlScheme.hasPrefix("pocketapp") {
            sharedMonkeyKing.oauthCompletionHandler?(nil, nil, nil)
            return true
        }
        // Alipay
        var canHandleAlipay = false
        if let customScheme = sharedMonkeyKing.customAlipayOrderScheme {
            if urlScheme == customScheme { canHandleAlipay = true }
        } else if urlScheme.hasPrefix("ap") {
            canHandleAlipay = true
        }
        if canHandleAlipay {
            let urlString = url.absoluteString
            if urlString.contains("//safepay/?") {
                var result = false
                defer {
                    sharedMonkeyKing.payCompletionHandler?(result)
                }
                guard
                    let query = url.query,
                    let response = query.monkeyking_urlDecodedString?.data(using: .utf8),
                    let json = response.monkeyking_json,
                    let memo = json["memo"] as? [String: Any],
                    let status = memo["ResultStatus"] as? String else {
                        return false
                }
                result = (status == "9000")
                return result
            } else {
                // Share
                guard
                    let account = sharedMonkeyKing.accountSet[.alipay] ,
                    let data = UIPasteboard.general.data(forPasteboardType: "com.alipay.openapi.pb.resp.\(account.appID)"),
                    let dict = try? PropertyListSerialization.propertyList(from: data, options: PropertyListSerialization.MutabilityOptions(), format: nil) as? [String: Any],
                    let objects = dict?["$objects"] as? NSArray,
                    let result = objects[12] as? Int else {
                        return false
                }
                let success = (result == 0)
                if success {
                    sharedMonkeyKing.deliverCompletionHandler?(.success(nil))
                } else {
                    sharedMonkeyKing.deliverCompletionHandler?(.failure(.sdk(reason: .unknown)))
                }
                return success
            }
        }
        return false
    }
}

// MARK: Share Message

extension MonkeyKing {

    public enum Media {
        case url(URL)
        case image(UIImage)
        case audio(audioURL: URL, linkURL: URL?)
        case video(URL)
        case file(Data)
    }

    public typealias Info = (title: String?, description: String?, thumbnail: UIImage?, media: Media?)

    public enum Message {

        public enum WeChatSubtype {
            case session(info: Info)
            case timeline(info: Info)
            case favorite(info: Info)

            var scene: String {
                switch self {
                case .session:
                    return "0"
                case .timeline:
                    return "1"
                case .favorite:
                    return "2"
                }
            }

            var info: Info {
                switch self {
                case .session(let info):
                    return info
                case .timeline(let info):
                    return info
                case .favorite(let info):
                    return info
                }
            }
        }
        case weChat(WeChatSubtype)

        public enum QQSubtype {
            case friends(info: Info)
            case zone(info: Info)
            case favorites(info: Info)
            case dataline(info: Info)

            var scene: Int {
                switch self {
                case .friends:
                    return 0x00
                case .zone:
                    return 0x01
                case .favorites:
                    return 0x08
                case .dataline:
                    return 0x10
                }
            }

            var info: Info {
                switch self {
                case .friends(let info):
                    return info
                case .zone(let info):
                    return info
                case .favorites(let info):
                    return info
                case .dataline(let info):
                    return info
                }
            }
        }
        case qq(QQSubtype)

        public enum WeiboSubtype {
            case `default`(info: Info, accessToken: String?)

            var info: Info {
                switch self {
                case .default(let info, _):
                    return info
                }
            }

            var accessToken: String? {
                switch self {
                case .default(_, let accessToken):
                    return accessToken
                }
            }
        }
        case weibo(WeiboSubtype)

        public enum AlipaySubtype {
            case friends(info: Info)
            case timeline(info: Info)

            var scene: NSNumber {
                switch self {
                case .friends:
                    return 0
                case .timeline:
                    return 1
                }
            }

            var info: Info {
                switch self {
                case .friends(let info):
                    return info
                case .timeline(let info):
                    return info
                }
            }
        }
        case alipay(AlipaySubtype)

        public enum TwitterSubtype {
            case `default`(info: Info, mediaIDs: [String]?, accessToken: String?, accessTokenSecret: String?)

            var info: Info {
                switch self {
                case .default(let info, _, _, _):
                    return info
                }
            }

            var mediaIDs: [String]? {
                switch self {
                case .default(_, let mediaIDs, _, _):
                    return mediaIDs
                }
            }

            var accessToken: String? {
                switch self {
                case .default(_, _,let accessToken, _):
                    return accessToken
                }
            }

            var accessTokenSecret: String? {
                switch self {
                case .default(_, _, _,let accessTokenSecret):
                    return accessTokenSecret
                }
            }
        }
        case twitter(TwitterSubtype)

        public var canBeDelivered: Bool {
            guard let account = sharedMonkeyKing.accountSet[self] else { return false }
            switch account {
            case .weibo, .twitter:
                return true
            default:
                break
            }
            return account.isAppInstalled
        }
    }

    public class func deliver(_ message: Message, completionHandler: @escaping DeliverCompletionHandler) {
        guard message.canBeDelivered else {
            completionHandler(.failure(.messageCanNotBeDelivered))
            return
        }
        sharedMonkeyKing.deliverCompletionHandler = completionHandler
        guard let account = sharedMonkeyKing.accountSet[message] else {
            completionHandler(.failure(.noAccount))
            return
        }
        let appID = account.appID
        switch message {
        case .weChat(let type):
            var weChatMessageInfo: [String: Any] = [
                "result": "1",
                "returnFromApp": "0",
                "scene": type.scene,
                "sdkver": "1.5",
                "command": "1010"
            ]
            let info = type.info
            if let title = info.title {
                weChatMessageInfo["title"] = title
            }
            if let description = info.description {
                weChatMessageInfo["description"] = description
            }
            if let thumbnailData = info.thumbnail?.monkeyking_compressedImageData {
                weChatMessageInfo["thumbData"] = thumbnailData
            }
            if let media = info.media {
                switch media {
                case .url(let url):
                    weChatMessageInfo["objectType"] = "5"
                    weChatMessageInfo["mediaUrl"] = url.absoluteString
                case .image(let image):
                    weChatMessageInfo["objectType"] = "2"
                    if let fileImageData = UIImageJPEGRepresentation(image, 1) {
                        weChatMessageInfo["fileData"] = fileImageData
                    }
                case .audio(let audioURL, let linkURL):
                    weChatMessageInfo["objectType"] = "3"
                    if let urlString = linkURL?.absoluteString {
                        weChatMessageInfo["mediaUrl"] = urlString
                    }
                    weChatMessageInfo["mediaDataUrl"] = audioURL.absoluteString
                case .video(let url):
                    weChatMessageInfo["objectType"] = "4"
                    weChatMessageInfo["mediaUrl"] = url.absoluteString
                case .file:
                    fatalError("WeChat not supports File type")
                }
            } else { // Text Share
                weChatMessageInfo["command"] = "1020"
            }
            let weChatMessage = [appID: weChatMessageInfo]
            guard let data = try? PropertyListSerialization.data(fromPropertyList: weChatMessage, format: .binary, options: 0) else { return }
            UIPasteboard.general.setData(data, forPasteboardType: "content")
            let weChatSchemeURLString = "weixin://app/\(appID)/sendreq/?"
            openURL(urlString: weChatSchemeURLString, completionHandler: { (flag) in
                if flag { return }
                completionHandler(.failure(.sdk(reason: .invalidURLScheme)))
            })
        case .qq(let type):
            let callbackName = appID.monkeyking_qqCallbackName
            var qqSchemeURLString = "mqqapi://share/to_fri?"
            if let encodedAppDisplayName = Bundle.main.monkeyking_displayName?.monkeyking_base64EncodedString {
                qqSchemeURLString += "thirdAppDisplayName=" + encodedAppDisplayName
            } else {
                qqSchemeURLString += "thirdAppDisplayName=" + "nixApp" // Should not be there
            }
            qqSchemeURLString += "&version=1&cflag=\(type.scene)"
            qqSchemeURLString += "&callback_type=scheme&generalpastboard=1"
            qqSchemeURLString += "&callback_name=\(callbackName)"
            qqSchemeURLString += "&src_type=app&shareType=0&file_type="
            if let media = type.info.media {
                func handleNews(with url: URL, mediaType: String?) {
                    if let thumbnailData = type.info.thumbnail?.monkeyking_compressedImageData {
                        let dic = ["previewimagedata": thumbnailData]
                        let data = NSKeyedArchiver.archivedData(withRootObject: dic)
                        UIPasteboard.general.setData(data, forPasteboardType: "com.tencent.mqq.api.apiLargeData")
                    }
                    qqSchemeURLString += mediaType ?? "news"
                    guard let encodedURLString = url.absoluteString.monkeyking_base64AndURLEncodedString else {
                        completionHandler(.failure(.sdk(reason: .urlEncodeFailed)))
                        return
                    }
                    qqSchemeURLString += "&url=\(encodedURLString)"
                }
                switch media {
                case .url(let url):
                    handleNews(with: url, mediaType: "news")
                case .image(let image):
                    guard let imageData = UIImageJPEGRepresentation(image, 1) else {
                        completionHandler(.failure(.invalidImageData))
                        return
                    }
                    var dic = [
                        "file_data": imageData
                    ]
                    if let thumbnail = type.info.thumbnail, let thumbnailData = UIImageJPEGRepresentation(thumbnail, 1) {
                        dic["previewimagedata"] = thumbnailData
                    }
                    let data = NSKeyedArchiver.archivedData(withRootObject: dic)
                    UIPasteboard.general.setData(data, forPasteboardType: "com.tencent.mqq.api.apiLargeData")
                    qqSchemeURLString += "img"
                case .audio(let audioURL, _):
                    handleNews(with: audioURL, mediaType: "audio")
                case .video(let url):
                    handleNews(with: url, mediaType: nil) // No video type, default is news type.
                case .file(let fileData):
                    let data = NSKeyedArchiver.archivedData(withRootObject: ["file_data": fileData])
                    UIPasteboard.general.setData(data, forPasteboardType: "com.tencent.mqq.api.apiLargeData")
                    qqSchemeURLString += "localFile"
                    if let filename = type.info.description?.monkeyking_urlEncodedString {
                        qqSchemeURLString += "&fileName=\(filename)"
                    }
                }
                if let encodedTitle = type.info.title?.monkeyking_base64AndURLEncodedString {
                    qqSchemeURLString += "&title=\(encodedTitle)"
                }
                if let encodedDescription = type.info.description?.monkeyking_base64AndURLEncodedString {
                    qqSchemeURLString += "&objectlocation=pasteboard&description=\(encodedDescription)"
                }
                qqSchemeURLString += "&sdkv=2.9"

            } else { // Share Text
                // fix #75
                switch type {
                case .zone:
                    qqSchemeURLString += "qzone&title="
                default:
                    qqSchemeURLString += "text&file_data="
                }
                if let encodedDescription = type.info.description?.monkeyking_base64AndURLEncodedString {
                    qqSchemeURLString += "\(encodedDescription)"
                }
            }
            openURL(urlString: qqSchemeURLString, completionHandler: { (flag) in
                if flag { return }
                completionHandler(.failure(.sdk(reason: .invalidURLScheme)))
            })
        case .weibo(let type):
            func errorReason(with reponseData: [String: Any]) -> Error.APIRequestReason {
                // ref: http://open.weibo.com/wiki/Error_code
                guard let errorCode = reponseData["error_code"] as? Int else {
                    return Error.APIRequestReason(type: .unrecognizedError, responseData: reponseData)
                }
                switch errorCode {
                case 21314, 21315, 21316, 21317, 21327, 21332:
                    return Error.APIRequestReason(type: .invalidToken, responseData: reponseData)
                default:
                    return Error.APIRequestReason(type: .unrecognizedError, responseData: reponseData)
                }
            }
            guard !sharedMonkeyKing.canOpenURL(urlString: "weibosdk://request") else {
                // App Share
                var messageInfo: [String: Any] = [
                    "__class": "WBMessageObject"
                ]
                let info = type.info
                if let description = info.description {
                    messageInfo["text"] = description
                }
                if let media = info.media {
                    switch media {
                    case .url(let url):
                        if let thumbnailData = info.thumbnail?.monkeyking_compressedImageData {
                            var mediaObject: [String: Any] = [
                                "__class": "WBWebpageObject",
                                "objectID": "identifier1"
                            ]
                            mediaObject["webpageUrl"] = url.absoluteString
                            mediaObject["title"] = info.title ?? ""
                            mediaObject["thumbnailData"] = thumbnailData
                            messageInfo["mediaObject"] = mediaObject
                        } else {
                            // Deliver text directly.
                            let text = info.description ?? ""
                            messageInfo["text"] = text.isEmpty ? url.absoluteString : text + " " + url.absoluteString
                        }
                    case .image(let image):
                        if let imageData = UIImageJPEGRepresentation(image, 1.0) {
                            messageInfo["imageObject"] = [
                                "imageData": imageData
                            ]
                        }
                    case .audio:
                        fatalError("Weibo not supports Audio type")
                    case .video:
                        fatalError("Weibo not supports Video type")
                    case .file:
                        fatalError("Weibo not supports File type")
                    }
                }
                let uuidString = UUID().uuidString
                let dict: [String: Any] = [
                    "__class": "WBSendMessageToWeiboRequest",
                    "message": messageInfo,
                    "requestID": uuidString
                ]
                let appData = NSKeyedArchiver.archivedData(withRootObject: [
                    "appKey": appID,
                    "bundleID": Bundle.main.monkeyking_bundleID ?? ""
                    ]
                )
                let messageData: [[String: Any]] = [
                    ["transferObject": NSKeyedArchiver.archivedData(withRootObject: dict)],
                    ["app": appData]
                ]
                UIPasteboard.general.items = messageData
                openURL(urlString: "weibosdk://request?id=\(uuidString)&sdkversion=003013000", completionHandler: { (flag) in
                    if flag { return }
                    completionHandler(.failure(.sdk(reason: .invalidURLScheme)))
                })
                return
            }
            // Weibo Web Share
            let info = type.info
            var parameters = [String: Any]()
            guard let accessToken = type.accessToken else {
                completionHandler(.failure(.noAccount))
                return
            }
            parameters["access_token"] = accessToken
            var status: [String?] = [info.title, info.description]
            var mediaType = Media.url(NSURL() as URL)
            if let media = info.media {
                switch media {
                case .url(let url):
                    status.append(url.absoluteString)
                    mediaType = Media.url(url)
                case .image(let image):
                    guard let imageData = UIImageJPEGRepresentation(image, 0.7) else {
                        completionHandler(.failure(.invalidImageData))
                        return
                    }
                    parameters["pic"] = imageData
                    mediaType = Media.image(image)
                case .audio:
                    fatalError("web Weibo not supports Audio type")
                case .video:
                    fatalError("web Weibo not supports Video type")
                case .file:
                    fatalError("web Weibo not supports File type")
                }
            }
            let statusText = status.flatMap({ $0 }).joined(separator: " ")
            parameters["status"] = statusText
            switch mediaType {
            case .url(_):
                let urlString = "https://api.weibo.com/2/statuses/share.json"
                sharedMonkeyKing.request(urlString, method: .post, parameters: parameters) { (responseData, HTTPResponse, error) in
                    var reason: Error.APIRequestReason
                    if error != nil {
                        reason = Error.APIRequestReason(type: .connectFailed, responseData: nil)
                        completionHandler(.failure(.apiRequest(reason: reason)))
                    } else if let responseData = responseData, (responseData["idstr"] as? String) == nil {
                        reason = errorReason(with: responseData)
                        completionHandler(.failure(.apiRequest(reason: reason)))
                    } else {
                        completionHandler(.success(nil))
                    }
                }
            case .image(_):
                let urlString = "https://api.weibo.com/2/statuses/share.json"
                sharedMonkeyKing.upload(urlString, parameters: parameters) { (responseData, HTTPResponse, error) in
                    var reason: Error.APIRequestReason
                    if error != nil {
                        reason = Error.APIRequestReason(type: .connectFailed, responseData: nil)
                        completionHandler(.failure(.apiRequest(reason: reason)))
                    } else if let responseData = responseData, (responseData["idstr"] as? String) == nil {
                        reason = errorReason(with: responseData)
                        completionHandler(.failure(.apiRequest(reason: reason)))
                    } else {
                        completionHandler(.success(nil))
                    }
                }
            case .audio:
                fatalError("web Weibo not supports Audio type")
            case .video:
                fatalError("web Weibo not supports Video type")
            case .file:
                fatalError("web Weibo not supports File type")
            }
        case .alipay(let type):
            let dictionary = createAlipayMessageDictionary(withScene: type.scene, info: type.info, appID: appID)
            guard let data = try? PropertyListSerialization.data(fromPropertyList: dictionary, format: .xml, options: 0) else {
                completionHandler(.failure(.sdk(reason: .serializeFailed)))
                return
            }
            UIPasteboard.general.setData(data, forPasteboardType: "com.alipay.openapi.pb.req.\(appID)")
            openURL(urlString: "alipayshare://platformapi/shareService?action=sendReq&shareId=\(appID)", completionHandler: { (flag) in
                if flag { return }
                completionHandler(.failure(.sdk(reason: .invalidURLScheme)))
            })
        case .twitter(let type):
            // MARK: - Twitter Deliver
            guard let accessToken = type.accessToken,
                  let accessTokenSecret = type.accessTokenSecret,
                  let account = sharedMonkeyKing.accountSet[.twitter] else {
                completionHandler(.failure(.noAccount))
                return
            }

            let info = type.info
            var status = [info.title, info.description]
            var parameters = [String: Any]()
            var mediaType = Media.url(NSURL() as URL)
            if let media = info.media {
                switch media {
                case .url(let url):
                    status.append(url.absoluteString)
                    mediaType = Media.url(url)
                case .image(let image):
                    guard let imageData = UIImageJPEGRepresentation(image, 0.7) else {
                        completionHandler(.failure(.invalidImageData))
                        return
                    }
                    parameters["media"] = imageData
                    mediaType = Media.image(image)
                default:
                    fatalError("web Twitter not supports this type")
                }
            }

            switch mediaType {
            case .url(_):
                let statusText = status.flatMap({ $0 }).joined(separator: " ")
                let updateStatusAPI = "https://api.twitter.com/1.1/statuses/update.json"

                var parameters = ["status": statusText]
                if let mediaIDs = type.mediaIDs {
                    parameters["media_ids"] = mediaIDs.joined(separator: ",")
                }

                if case .twitter(let appID, let appKey, _) = account {
                    let oauthString = Networking.sharedInstance.authorizationHeader(for: .post, urlString: updateStatusAPI, appID: appID, appKey: appKey, accessToken: accessToken, accessTokenSecret: accessTokenSecret, parameters: parameters, isMediaUpload: true)
                    let headers = ["Authorization": oauthString]
                    // ref: https://dev.twitter.com/rest/reference/post/statuses/update
                    let urlString = "\(updateStatusAPI)?\(parameters.urlEncodedQueryString(using: .utf8))"
                    sharedMonkeyKing.request(urlString, method: .post, parameters: nil, headers: headers) { (responseData, URLResponse, error) in
                        var reason: Error.APIRequestReason
                        if error != nil {
                            reason = Error.APIRequestReason(type: .connectFailed, responseData: nil)
                            completionHandler(.failure(.apiRequest(reason: reason)))
                        } else {
                            if let HTTPResponse = URLResponse as? HTTPURLResponse,
                                HTTPResponse.statusCode == 200 {
                                completionHandler(.success(nil))
                                return
                            }
                            if let responseData = responseData,
                               let _ = responseData["errors"] {
                                reason = sharedMonkeyKing.errorReason(with: responseData, at: .twitter)
                                completionHandler(.failure(.apiRequest(reason: reason)))
                                return
                            }
                            let unrecognizedReason = Error.APIRequestReason(type: .unrecognizedError, responseData: responseData)
                            completionHandler(.failure(.apiRequest(reason: unrecognizedReason)))
                        }
                    }
                }
            case .image(_):
                let uploadMediaAPI = "https://upload.twitter.com/1.1/media/upload.json"
                if case .twitter(let appID, let appKey, _) = account {
                    // ref: https://dev.twitter.com/rest/media/uploading-media#keepinmind
                    let oauthString = Networking.sharedInstance.authorizationHeader(for: .post, urlString: uploadMediaAPI, appID: appID, appKey: appKey, accessToken: accessToken, accessTokenSecret: accessTokenSecret, parameters: nil, isMediaUpload: false)
                    let headers = ["Authorization": oauthString]

                    sharedMonkeyKing.upload(uploadMediaAPI, parameters: parameters, headers: headers) { (responseData, URLResponse, error) in
                        if let statusCode = (URLResponse as? HTTPURLResponse)?.statusCode,
                            statusCode == 200 {
                            completionHandler(.success(responseData))
                            return
                        }

                        var reason: Error.APIRequestReason
                        if let _ = error {
                            reason = Error.APIRequestReason(type: .connectFailed, responseData: nil)
                        } else {
                            reason = Error.APIRequestReason(type: .unrecognizedError, responseData: responseData)
                        }

                        completionHandler(.failure(.apiRequest(reason: reason)))
                    }

                }
            default:
                fatalError("web Twitter not supports this type")
            }

        }
    }
}

// MARK: Pay

extension MonkeyKing {

    public enum Order {
        /// You can custom URL scheme. Default "ap" + String(appID)
        /// ref: https://doc.open.alipay.com/docs/doc.htm?spm=a219a.7629140.0.0.piSRlm&treeId=204&articleId=105295&docType=1
        case alipay(urlString: String, scheme: String?)
        case weChat(urlString: String)

        public var canBeDelivered: Bool {
            var scheme = ""
            switch self {
            case .alipay:
                scheme = "alipay://"
            case .weChat:
                scheme = "weixin://"
            }
            guard !scheme.isEmpty else { return false }
            return sharedMonkeyKing.canOpenURL(urlString: scheme)
        }
    }

    public class func deliver(_ order: Order, completionHandler: @escaping PayCompletionHandler) {
        if !order.canBeDelivered {
            completionHandler(false)
            return
        }
        sharedMonkeyKing.payCompletionHandler = completionHandler
        switch order {
        case .weChat(let urlString):
            openURL(urlString: urlString, completionHandler: { (flag) in
                if flag { return }
                completionHandler(false)
            })
        case let .alipay(urlString, scheme):
            sharedMonkeyKing.customAlipayOrderScheme = scheme
            openURL(urlString: urlString, completionHandler: { (flag) in
                if flag { return }
                completionHandler(false)
            })
        }
    }
}

// MARK: OAuth

extension MonkeyKing {

    public class func oauth(for platform: SupportedPlatform, scope: String? = nil, requestToken: String? = nil, completionHandler: @escaping OAuthCompletionHandler) {
        guard let account = sharedMonkeyKing.accountSet[platform] else { return }
        guard account.isAppInstalled || account.canWebOAuth else {
            let error = NSError(domain: "App is not installed", code: -2, userInfo: nil)
            completionHandler(nil, nil, error)
            return
        }
        sharedMonkeyKing.oauthCompletionHandler = completionHandler
        switch account {
        case .weChat(let appID, _):
            let scope = scope ?? "snsapi_userinfo"
            if !account.isAppInstalled {
                // SMS OAuth
                // uid??
                let accessTokenAPI = "https://open.weixin.qq.com/connect/mobilecheck?appid=\(appID)&uid=1926559385"
                addWebView(withURLString: accessTokenAPI)
            } else {
                openURL(urlString: "weixin://app/\(appID)/auth/?scope=\(scope)&state=Weixinauth", completionHandler: { (flag) in
                    if flag { return }
                    completionHandler(nil, nil, NSError(domain: "OAuth Error, cannot open url weixin://", code: -1, userInfo: nil))
                })
            }
        case .qq(let appID):
            let scope = scope ?? ""
            guard !account.isAppInstalled else {
                let appName = Bundle.main.monkeyking_displayName ?? "nixApp"
                let dic = [
                    "app_id": appID,
                    "app_name": appName,
                    "client_id": appID,
                    "response_type": "token",
                    "scope": scope,
                    "sdkp": "i",
                    "sdkv": "2.9",
                    "status_machine": UIDevice.current.model,
                    "status_os": UIDevice.current.systemVersion,
                    "status_version": UIDevice.current.systemVersion
                ]
                let data = NSKeyedArchiver.archivedData(withRootObject: dic)
                UIPasteboard.general.setData(data, forPasteboardType: "com.tencent.tencent\(appID)")
                openURL(urlString: "mqqOpensdkSSoLogin://SSoLogin/tencent\(appID)/com.tencent.tencent\(appID)?generalpastboard=1", completionHandler: { (flag) in
                    if flag { return }
                    completionHandler(nil, nil, NSError(domain: "OAuth Error, cannot open url mqqOpensdkSSoLogin://", code: -1, userInfo: nil))
                })
                return
            }
            // Web OAuth
            let accessTokenAPI = "https://xui.ptlogin2.qq.com/cgi-bin/xlogin?appid=716027609&pt_3rd_aid=209656&style=35&s_url=http%3A%2F%2Fconnect.qq.com&refer_cgi=m_authorize&client_id=\(appID)&redirect_uri=auth%3A%2F%2Fwww.qq.com&response_type=token&scope=\(scope)"
            addWebView(withURLString: accessTokenAPI)
        case .weibo(let appID, _, let redirectURL):
            let scope = scope ?? "all"
            guard !account.isAppInstalled else {
                let uuidString = UUID().uuidString
                let transferObjectData = NSKeyedArchiver.archivedData(withRootObject: [
                    "__class": "WBAuthorizeRequest",
                    "redirectURI": redirectURL,
                    "requestID": uuidString,
                    "scope": scope
                    ]
                )
                let userInfoData = NSKeyedArchiver.archivedData(withRootObject: [
                    "mykey": "as you like",
                    "SSO_From": "SendMessageToWeiboViewController"
                    ]
                )
                let appData = NSKeyedArchiver.archivedData(withRootObject: [
                    "appKey": appID,
                    "bundleID": Bundle.main.monkeyking_bundleID ?? "",
                    "name": Bundle.main.monkeyking_displayName ?? ""
                    ]
                )
                let authItems: [[String: Any]] = [
                    ["transferObject": transferObjectData],
                    ["userInfo": userInfoData],
                    ["app": appData]
                ]
                UIPasteboard.general.items = authItems
                openURL(urlString: "weibosdk://request?id=\(uuidString)&sdkversion=003013000", completionHandler: { (flag) in
                    if flag { return }
                    completionHandler(nil, nil, NSError(domain: "OAuth Error, cannot open url weibosdk://", code: -1, userInfo: nil))
                })
                return
            }
            // Web OAuth
            let accessTokenAPI = "https://api.weibo.com/oauth2/authorize?client_id=\(appID)&response_type=code&redirect_uri=\(redirectURL)&scope=\(scope)"
            addWebView(withURLString: accessTokenAPI)
        case .pocket(let appID):
            guard let startIndex = appID.range(of: "-")?.lowerBound else {
                return
            }
            let prefix = appID.substring(to: startIndex)
            let redirectURLString = "pocketapp\(prefix):authorizationFinished"
            guard let requestToken = requestToken else { return }
            guard !account.isAppInstalled else {
                let requestTokenAPI = "pocket-oauth-v1:///authorize?request_token=\(requestToken)&redirect_uri=\(redirectURLString)"
                openURL(urlString: requestTokenAPI, completionHandler: { (flag) in
                    if flag { return }
                    completionHandler(nil, nil, NSError(domain: "OAuth Error, cannot open url pocket-oauth-v1://", code: -1, userInfo: nil))
                })
                return
            }
            let requestTokenAPI = "https://getpocket.com/auth/authorize?request_token=\(requestToken)&redirect_uri=\(redirectURLString)"
            DispatchQueue.main.async {
                addWebView(withURLString: requestTokenAPI)
            }
        case .twitter(let appID, let appKey, let redirectURL):
            sharedMonkeyKing.twitterAuthenticate(appID: appID, appKey: appKey, redirectURL: redirectURL)
        case .alipay:
            break
        }
    }

    // Twitter Authenticate
    // https://dev.twitter.com/web/sign-in/implementing
    fileprivate func twitterAuthenticate(appID: String, appKey: String, redirectURL: String) {

        let requestTokenAPI = "https://api.twitter.com/oauth/request_token"
        let oauthString = Networking.sharedInstance.authorizationHeader(for: .post, urlString: requestTokenAPI, appID: appID, appKey: appKey, accessToken: nil, accessTokenSecret: nil, parameters: ["oauth_callback": redirectURL], isMediaUpload: false)
        let oauthHeader = ["Authorization": oauthString]
        Networking.sharedInstance.request(requestTokenAPI, method: .post, parameters: nil, encoding: .url, headers: oauthHeader) { (responseData, httpResponse, error) in
            if let responseData = responseData,
                let requestToken = (responseData["oauth_token"] as? String) {
                let loginURL = "https://api.twitter.com/oauth/authenticate?oauth_token=\(requestToken)"
                MonkeyKing.addWebView(withURLString: loginURL)
            }
        }
    }
}

