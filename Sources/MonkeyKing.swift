//
//  MonkeyKing.swift
//  MonkeyKing
//
//  Created by NIX on 15/9/11.
//  Copyright © 2015年 nixWork. All rights reserved.
//

import UIKit
import WebKit

public func ==(lhs: MonkeyKing.Account, rhs: MonkeyKing.Account) -> Bool {
    return lhs.appID == rhs.appID
}

open class MonkeyKing: NSObject {

    public typealias DeliverCompletionHandler = (_ result: Bool) -> Void
    public typealias OAuthCompletionHandler = (NSDictionary?, URLResponse?, NSError?) -> Void
    public typealias PayCompletionHandler = (_ result: Bool) -> Void

    fileprivate static let sharedMonkeyKing = MonkeyKing()

    fileprivate var accountSet = Set<Account>()

    fileprivate var deliverCompletionHandler: DeliverCompletionHandler?
    fileprivate var oauthCompletionHandler: OAuthCompletionHandler?
    fileprivate var payCompletionHandler: PayCompletionHandler?

    fileprivate var webView: WKWebView?
    
    fileprivate override init() {}

    public enum Account: Hashable {

        case weChat(appID: String, appKey: String?)
        case qq(appID: String)
        case weibo(appID: String, appKey: String, redirectURL: String)
        case pocket(appID: String)
        case alipay(appID: String)

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
            }
        }

        public var hashValue: Int {
            return appID.hashValue
        }

        public var canWebOAuth: Bool {
            switch self {
            case .qq, .weibo, .pocket, .weChat:
                return true
            default:
                return false
            }
        }
    }

    public enum SupportedPlatform {
        case qq
        case weChat
        case weibo
        case pocket(requestToken: String)
        case alipay
    }

    open class func registerAccount(_ account: Account) {

        guard account.isAppInstalled || account.canWebOAuth else {
            return
        }

        for oldAccount in MonkeyKing.sharedMonkeyKing.accountSet {

            switch oldAccount {

            case .weChat:
                if case .weChat = account {
                    sharedMonkeyKing.accountSet.remove(oldAccount)
                }
            case .qq:
                if case .qq = account {
                    sharedMonkeyKing.accountSet.remove(oldAccount)
                }
            case .weibo:
                if case .weibo = account {
                    sharedMonkeyKing.accountSet.remove(oldAccount)
                }
            case .pocket:
                if case .pocket = account {
                    sharedMonkeyKing.accountSet.remove(oldAccount)
                }
            case .alipay:
                if case .alipay = account {
                    sharedMonkeyKing.accountSet.remove(oldAccount)
                }
            }
        }

        sharedMonkeyKing.accountSet.insert(account)
    }
}


// MARK: OpenURL Handler

extension MonkeyKing {

    public class func handleOpenURL(_ url: URL) -> Bool {

        guard let urlScheme = url.scheme else {
            return false
        }

        if urlScheme.hasPrefix("wx") {

            let urlString = url.absoluteString

            // WeChat OAuth
            if urlString.contains("state=Weixinauth") {

                let queryDictionary = url.monkeyking_queryDictionary
                guard let code = queryDictionary["code"] as? String else {
                    return false
                }

                // Login Succcess
                fetchWeChatOAuthInfoByCode(code: code) { (info, response, error) -> Void in
                    sharedMonkeyKing.oauthCompletionHandler?(info, response, error)
                }

                return true
            }
            
            // WeChat SMS OAuth
            if urlString.contains("wapoauth") {
                
                let queryDictionary = url.monkeyking_queryDictionary
                guard let m = queryDictionary["m"] as? String, let t = queryDictionary["t"] as? String else {
                    return false
                }
                
                guard let account = sharedMonkeyKing.accountSet[.weChat] else {
                    return false
                }
                
                let appID = account.appID
                
                let urlString = "https://open.weixin.qq.com/connect/smsauthorize?appid=\(appID)&redirect_uri=\(appID)%3A%2F%2Foauth&response_type=code&scope=snsapi_message,snsapi_userinfo,snsapi_friend,snsapi_contact&state=xxx&uid=1926559385&m=\(m)&t=\(t)"
                
                addWebView(withURLString: urlString)

                return true
            }
            
            if urlString.contains("://pay/") {

                var result = false

                defer {
                    sharedMonkeyKing.payCompletionHandler?(result)
                }

                let queryDictionary = url.monkeyking_queryDictionary
                guard let ret = queryDictionary["ret"] as? String else {
                    return false
                }
                
                result = (ret == "0")
                
                return result
            }

            // WeChat Share
            guard let data = UIPasteboard.general.data(forPasteboardType: "content") else {
                return false
            }

            if let dict = try? PropertyListSerialization.propertyList(from: data, options: PropertyListSerialization.MutabilityOptions(), format: nil) as? NSDictionary {

                guard let account = sharedMonkeyKing.accountSet[.weChat],
                    let dic = dict?[account.appID] as? NSDictionary,
                    let result = Int(dic["result"] as? String ?? "") else {
                        return false
                }

                let success = (result == 0)
                sharedMonkeyKing.deliverCompletionHandler?(success)

                return success
            }
        }

        // QQ Share
        if urlScheme.hasPrefix("QQ") {

            guard let error = url.monkeyking_queryDictionary["error"] as? String else {
                return false
            }

            let success = (error == "0")

            sharedMonkeyKing.deliverCompletionHandler?(success)

            return success
        }

        // QQ OAuth
        if urlScheme.hasPrefix("tencent") {

            guard let account = sharedMonkeyKing.accountSet[.qq] else {
                return false
            }

            var userInfoDictionary: NSDictionary?
            var error: NSError?

            defer {
                sharedMonkeyKing.oauthCompletionHandler?(userInfoDictionary, nil, error)
            }

            guard let data = UIPasteboard.general.data(forPasteboardType: "com.tencent.tencent\(account.appID)"),
                let dic = NSKeyedUnarchiver.unarchiveObject(with: data) as? NSDictionary else {
                    error = NSError(domain: "OAuth Error", code: -1, userInfo: nil)
                    return false
            }

            guard let result = dic["ret"] as? Int, result == 0 else {
                if let errorDomatin = dic["user_cancelled"] as? String, errorDomatin == "YES" {
                    error = NSError(domain: "User Cancelled", code: -2, userInfo: nil)
                } else {
                    error = NSError(domain: "OAuth Error", code: -1, userInfo: nil)
                }
                return false
            }

            userInfoDictionary = dic

            return true
        }

        // Weibo
        if urlScheme.hasPrefix("wb") {

            let items = UIPasteboard.general.items
            var results = [String: AnyObject]()

            for item in items {
                for (key, value) in item {
                    if let valueData = value as? Data, key == "transferObject" {
                        results[key] = NSKeyedUnarchiver.unarchiveObject(with: valueData) as AnyObject?
                    }
                }
            }

            guard let responseData = results["transferObject"] as? [String: AnyObject],
                let type = responseData["__class"] as? String else {
                    return false
            }

            guard let statusCode = responseData["statusCode"] as? Int else {
                return false
            }

            switch type {

                // Weibo OAuth
            case "WBAuthorizeResponse":

                var userInfoDictionary: NSDictionary?
                var error: NSError?

                defer {
                    sharedMonkeyKing.oauthCompletionHandler?(responseData as NSDictionary?, nil, error)
                }

                userInfoDictionary = responseData as NSDictionary?

                if statusCode != 0 {
                    error = NSError(domain: "OAuth Error", code: -1, userInfo: nil)
                    return false
                }
                return true

                // Weibo Share
            case "WBSendMessageToWeiboResponse":

                let success = (statusCode == 0)
                sharedMonkeyKing.deliverCompletionHandler?(success)
                
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
        if urlScheme.hasPrefix("ap") {

            let urlString = url.absoluteString

            if urlString.contains("//safepay/?") {

                var result = false

                defer {
                    sharedMonkeyKing.payCompletionHandler?(result)
                }

                guard let query = url.query,
                    let response = query.monkeyking_urlDecodedString?.data(using: String.Encoding.utf8),
                    let json = response.monkeyking_json else {
                        return false
                }

                guard let memo = json["memo"], let status = memo["ResultStatus"] as? String else {
                    return false
                }

                result = status == "9000"

                return result

            } else {

                // Alipay Share
                guard let account = sharedMonkeyKing.accountSet[.alipay],
                    let data = UIPasteboard.general.data(forPasteboardType: "com.alipay.openapi.pb.resp.\(account.appID)"),
                    let dict = try? PropertyListSerialization.propertyList(from: data, options: PropertyListSerialization.MutabilityOptions(), format: nil) as? NSDictionary,
                    let objects = dict?["$objects"] as? NSArray,
                    let result = objects[12] as? Int else {
                        return false
                }

                let success = (result == 0)
                sharedMonkeyKing.deliverCompletionHandler?(success)
                
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

            var scene: Int {
                switch self {
                case .friends:
                    return 0
                }
            }

            var info: Info {
                switch self {
                case .friends(let info):
                    return info
                }
            }
        }
        case alipay(AlipaySubtype)

        public var canBeDelivered: Bool {

            guard let account = sharedMonkeyKing.accountSet[self] else {
                return false
            }

            if case .weibo = account {
                return true
            }
            
            return account.isAppInstalled
        }
    }

    public class func deliver(_ message: Message, completionHandler: @escaping DeliverCompletionHandler) {

        guard message.canBeDelivered else {
            completionHandler(false)
            return
        }

        sharedMonkeyKing.deliverCompletionHandler = completionHandler

        guard let account = sharedMonkeyKing.accountSet[message] else {
            completionHandler(false)
            return
        }

        let appID = account.appID

        switch message {

        case .weChat(let type):

            var weChatMessageInfo: [String: AnyObject] = [
                "result": "1" as AnyObject,
                "returnFromApp": "0" as AnyObject,
                "scene": type.scene as AnyObject,
                "sdkver": "1.5" as AnyObject,
                "command": "1010" as AnyObject,
            ]

            let info = type.info

            if let title = info.title {
                weChatMessageInfo["title"] = title as AnyObject?
            }

            if let description = info.description {
                weChatMessageInfo["description"] = description as AnyObject?
            }

            if let thumbnailData = info.thumbnail?.monkeyking_compressedImageData {
                weChatMessageInfo["thumbData"] = thumbnailData as AnyObject?
            }

            if let media = info.media {
                switch media {

                case .url(let url):
                    weChatMessageInfo["objectType"] = "5" as AnyObject?

                    weChatMessageInfo["mediaUrl"] = url.absoluteString as AnyObject?

                case .image(let image):
                    weChatMessageInfo["objectType"] = "2" as AnyObject?

                    if let fileImageData = UIImageJPEGRepresentation(image, 1) {
                        weChatMessageInfo["fileData"] = fileImageData as AnyObject?
                    }

                case .audio(let audioURL, let linkURL):
                    weChatMessageInfo["objectType"] = "3" as AnyObject?

                    weChatMessageInfo["mediaUrl"] = linkURL?.absoluteString as AnyObject?

                    weChatMessageInfo["mediaDataUrl"] = audioURL.absoluteString as AnyObject?

                case .video(let url):
                    weChatMessageInfo["objectType"] = "4" as AnyObject?

                    weChatMessageInfo["mediaUrl"] = url.absoluteString as AnyObject?

                case .file:
                    fatalError("WeChat not supports File type")
                }

            } else { // Text Share
                weChatMessageInfo["command"] = "1020" as AnyObject?
            }

            let weChatMessage = [appID: weChatMessageInfo]

            guard let data = try? PropertyListSerialization.data(fromPropertyList: weChatMessage, format: .binary, options: 0) else {
                return
            }

            UIPasteboard.general.setData(data, forPasteboardType: "content")

            let weChatSchemeURLString = "weixin://app/\(appID)/sendreq/?"

            if !openURL(urlString: weChatSchemeURLString) {
                completionHandler(false)
            }

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

                    if let thumbnail = type.info.thumbnail, let thumbnailData = UIImageJPEGRepresentation(thumbnail, 1) {
                        let dic = ["previewimagedata": thumbnailData]
                        let data = NSKeyedArchiver.archivedData(withRootObject: dic)
                        UIPasteboard.general.setData(data, forPasteboardType: "com.tencent.mqq.api.apiLargeData")
                    }

                    qqSchemeURLString += mediaType ?? "news"

                    guard let encodedURLString = url.absoluteString.monkeyking_base64AndURLEncodedString else {
                        completionHandler(false)
                        return
                    }

                    qqSchemeURLString += "&url=\(encodedURLString)"
                }

                switch media {

                case .url(let url):

                    handleNews(with: url, mediaType: "news")

                case .image(let image):

                    guard let imageData = UIImageJPEGRepresentation(image, 1) else {
                        completionHandler(false)
                        return
                    }

                    var dic = [
                        "file_data": imageData,
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

            } else { // Share Text
                qqSchemeURLString += "text&file_data="

                if let encodedDescription = type.info.description?.monkeyking_base64AndURLEncodedString {
                    qqSchemeURLString += "\(encodedDescription)"
                }
            }

            if !openURL(urlString: qqSchemeURLString) {
                completionHandler(false)
            }

        case .weibo(let type):

            guard !sharedMonkeyKing.canOpenURL(urlString: "weibosdk://request") else {

                // App Share

                var messageInfo: [String: AnyObject] = ["__class": "WBMessageObject" as AnyObject]
                let info = type.info

                if let description = info.description {
                    messageInfo["text"] = description as AnyObject?
                }

                if let media = info.media {
                    switch media {
                    case .url(let url):

                        var mediaObject: [String: AnyObject] = [
                            "__class": "WBWebpageObject" as AnyObject,
                            "objectID": "identifier1" as AnyObject
                        ]

                        if let title = info.title {
                            mediaObject["title"] = title as AnyObject?
                        }

                        if let thumbnailImage = info.thumbnail,
                            let thumbnailData = UIImageJPEGRepresentation(thumbnailImage, 0.7) {
                                mediaObject["thumbnailData"] = thumbnailData as AnyObject?
                        }

                        mediaObject["webpageUrl"] = url.absoluteString as AnyObject?

                        messageInfo["mediaObject"] = mediaObject as AnyObject?

                    case .image(let image):

                        if let imageData = UIImageJPEGRepresentation(image, 1.0) {
                            messageInfo["imageObject"] = ["imageData": imageData] as NSDictionary
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
                let dict = ["__class": "WBSendMessageToWeiboRequest", "message": messageInfo, "requestID": uuidString] as [String : Any]

                let messageData: [[String: AnyObject]] = [
                    ["transferObject": NSKeyedArchiver.archivedData(withRootObject: dict) as AnyObject],
                    ["app": NSKeyedArchiver.archivedData(withRootObject: ["appKey": appID, "bundleID": Bundle.main.monkeyking_bundleID ?? ""]) as AnyObject]
                ]

                UIPasteboard.general.items = messageData

                if !openURL(urlString: "weibosdk://request?id=\(uuidString)&sdkversion=003013000") {
                    completionHandler(false)
                }

                return
            }

            // Weibo Web Share

            let info = type.info
            var parameters = [String: AnyObject]()

            guard let accessToken = type.accessToken else {
                print("When Weibo did not install, accessToken must need")
                completionHandler(false)
                return
            }

            parameters["access_token"] = accessToken as AnyObject?

            var status: [String?] = [info.title, info.description]

            var mediaType = Media.url(NSURL() as URL)

            if let media = info.media {

                switch media {

                case .url(let url):

                    status.append(url.absoluteString)

                    mediaType = Media.url(url)

                case .image(let image):

                    guard let imageData = UIImageJPEGRepresentation(image, 0.7) else {
                        completionHandler(false)
                        return
                    }

                    parameters["pic"] = imageData as AnyObject?
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
            parameters["status"] = statusText as AnyObject?
            
            switch mediaType {
                
            case .url(_):
                
                let urlString = "https://api.weibo.com/2/statuses/update.json"
                
                sharedMonkeyKing.request(urlString, method: .post, parameters: parameters) { (responseData, HTTPResponse, error) -> Void in
                    if let json = responseData, let _ = json["idstr"] as? String {
                        completionHandler(true)
                    } else {
                        print("responseData \(responseData) HTTPResponse \(HTTPResponse)")
                        completionHandler(false)
                    }
                }
                
            case .image(_):
                
                let urlString = "https://upload.api.weibo.com/2/statuses/upload.json"
                
                sharedMonkeyKing.upload(urlString, parameters: parameters) { (responseData, HTTPResponse, error) -> Void in
                    if let json = responseData, let _ = json["idstr"] as? String {
                        completionHandler(true)
                    } else {
                        print("responseData \(responseData) HTTPResponse \(HTTPResponse)")
                        completionHandler(false)
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

            let dictionary = createAlipayMessageDictionary(info: type.info, appID: appID)
            guard let data = try? PropertyListSerialization.data(fromPropertyList: dictionary, format: .xml, options: 0) else {
                completionHandler(false)
                return
            }

            UIPasteboard.general.setData(data, forPasteboardType: "com.alipay.openapi.pb.req.\(appID)")
            if !openURL(urlString: "alipayshare://platformapi/shareService?action=sendReq&shareId=\(appID)") {
                completionHandler(false)
            }
        }
    }
}


// MARK: Pay

extension MonkeyKing {
    
    public enum Order {

        case alipay(urlString: String)
        case weChat(urlString: String)
        
        public var canBeDelivered: Bool {
            var scheme = ""
            switch self {
            case .alipay:
                scheme = "alipay://"
            case .weChat:
                scheme = "weixin://"
            }
            
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
            if !openURL(urlString: urlString) {
                completionHandler(false)
            }
            
        case .alipay(let urlString):
            if !openURL(urlString: urlString) {
                completionHandler(false)
            }
        }
        
    }
}


// MARK: OAuth

extension MonkeyKing {

    public class func oauth(for platform: SupportedPlatform, scope: String? = nil, completionHandler: @escaping OAuthCompletionHandler) {

        guard let account = sharedMonkeyKing.accountSet[platform] else {
            return
        }

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

                if !openURL(urlString: "weixin://app/\(appID)/auth/?scope=\(scope)&state=Weixinauth") {
                    completionHandler(nil, nil, NSError(domain: "OAuth Error, cannot open url weixin://", code: -1, userInfo: nil))
                }
            }
            
        case .qq(let appID):

            let scope = scope ?? ""
            guard !account.isAppInstalled else {
                let appName = Bundle.main.monkeyking_displayName ?? "nixApp"
                let dic = ["app_id": appID,
                    "app_name": appName,
                    "client_id": appID,
                    "response_type": "token",
                    "scope": scope,
                    "sdkp": "i",
                    "sdkv": "2.9",
                    "status_machine": UIDevice.current.model,
                    "status_os": UIDevice.current.systemVersion,
                    "status_version": UIDevice.current.systemVersion]

                let data = NSKeyedArchiver.archivedData(withRootObject: dic)
                UIPasteboard.general.setData(data, forPasteboardType: "com.tencent.tencent\(appID)")

                if !openURL(urlString: "mqqOpensdkSSoLogin://SSoLogin/tencent\(appID)/com.tencent.tencent\(appID)?generalpastboard=1") {
                    completionHandler(nil, nil, NSError(domain: "OAuth Error, cannot open url mqqOpensdkSSoLogin://", code: -1, userInfo: nil))
                }

                return
            }

            // Web OAuth

            let accessTokenAPI = "http://xui.ptlogin2.qq.com/cgi-bin/xlogin?appid=716027609&pt_3rd_aid=209656&style=35&s_url=http%3A%2F%2Fconnect.qq.com&refer_cgi=m_authorize&client_id=\(appID)&redirect_uri=auth%3A%2F%2Fwww.qq.com&response_type=token&scope=\(scope)"
            addWebView(withURLString: accessTokenAPI)

        case .weibo(let appID, _, let redirectURL):

            let scope = scope ?? "all"

            guard !account.isAppInstalled else {
                let uuIDString = UUID().uuidString
                let authData: [[String: AnyObject]] = [
                    ["transferObject": NSKeyedArchiver.archivedData(withRootObject: ["__class": "WBAuthorizeRequest", "redirectURI": redirectURL, "requestID":uuIDString, "scope": scope]) as AnyObject
                    ],
                    ["userInfo": NSKeyedArchiver.archivedData(withRootObject: ["mykey": "as you like", "SSO_From": "SendMessageToWeiboViewController"]) as AnyObject],
                    ["app": NSKeyedArchiver.archivedData(withRootObject: ["appKey": appID, "bundleID": Bundle.main.monkeyking_bundleID ?? "", "name": Bundle.main.monkeyking_displayName ?? ""]) as AnyObject]
                ]

                UIPasteboard.general.items = authData
                if !openURL(urlString: "weibosdk://request?id=\(uuIDString)&sdkversion=003013000") {
                    completionHandler(nil, nil, NSError(domain: "OAuth Error, cannot open url weibosdk://", code: -1, userInfo: nil))
                }
                return
            }

            // Web OAuth
            let accessTokenAPI = "https://open.weibo.cn/oauth2/authorize?client_id=\(appID)&response_type=code&redirect_uri=\(redirectURL)&scope=\(scope)"
            addWebView(withURLString: accessTokenAPI)

        case .pocket(let appID):

            guard let startIndex = appID.range(of: "-")?.lowerBound else {
                return
            }
            let prefix = appID.substring(to: startIndex)
            let redirectURLString = "pocketapp\(prefix):authorizationFinished"

            var _requestToken: String?
            if case .pocket(let token) = platform {
                _requestToken = token
            }

            guard let requestToken = _requestToken else {
                return
            }

            guard !account.isAppInstalled else {
                let requestTokenAPI = "pocket-oauth-v1:///authorize?request_token=\(requestToken)&redirect_uri=\(redirectURLString)"
                if !openURL(urlString: requestTokenAPI) {
                    completionHandler(nil, nil, NSError(domain: "OAuth Error, cannot open url pocket-oauth-v1://", code: -1, userInfo: nil))
                }
                return
            }

            let requestTokenAPI = "https://getpocket.com/auth/authorize?request_token=\(requestToken)&redirect_uri=\(redirectURLString)"
            DispatchQueue.main.async {
                addWebView(withURLString: requestTokenAPI)
            }
        case .alipay:
            break
        }
    }
}


// MARK: WKNavigationDelegate

extension MonkeyKing: WKNavigationDelegate {

    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {

        // Pocket OAuth
        if let errorString = (error as NSError).userInfo["NSErrorFailingURLStringKey"] as? String, errorString.hasSuffix(":authorizationFinished") {
            removeWebView(webView, tuples: (nil, nil, nil))
        }
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {

        activityIndicatorViewAction(webView, stop: true)

        guard let urlString = webView.url?.absoluteString else {
            return
        }

        var scriptString = "var button = document.createElement('a'); button.setAttribute('href', 'about:blank'); button.innerHTML = '关闭'; button.setAttribute('style', 'width: calc(100% - 40px); background-color: gray;display: inline-block;height: 40px;line-height: 40px;text-align: center;color: #777777;text-decoration: none;border-radius: 3px;background: linear-gradient(180deg, white, #f1f1f1);border: 1px solid #CACACA;box-shadow: 0 2px 3px #DEDEDE, inset 0 0 0 1px white;text-shadow: 0 2px 0 white;position: fixed;left: 0;bottom: 0;margin: 20px;font-size: 18px;'); document.body.appendChild(button);"

        if urlString.contains("getpocket.com") {
            scriptString += "document.querySelector('div.toolbar').style.display = 'none';"
            scriptString += "document.querySelector('a.extra_action').style.display = 'none';"
            scriptString += "var rightButton = $('.toolbarContents div:last-child');"
            scriptString += "if (rightButton.html() == 'Log In') {rightButton.click()}"

        } else if urlString.contains("open.weibo.cn") {
            scriptString += "document.querySelector('aside.logins').style.display = 'none';"
        }

        webView.evaluateJavaScript(scriptString, completionHandler: nil)
    }

    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {

        guard let url = webView.url else {
            webView.stopLoading()
            return
        }

        // Close Button
        if url.absoluteString.contains("about:blank") {
            let error = NSError(domain: "User Cancelled", code: -1, userInfo: nil)
            removeWebView(webView, tuples: (nil, nil, error))
            return
        }

        // QQ Web OAuth
        guard url.absoluteString.contains("&access_token=") && url.absoluteString.contains("qq.com") else {
            return
        }

        guard let fragment = url.fragment?.characters.dropFirst(), let newURL = URL(string: "http://qzs.qq.com/?\(String(fragment))") else {
            return
        }

        let queryDictionary = newURL.monkeyking_queryDictionary as NSDictionary
        removeWebView(webView, tuples: (queryDictionary, nil, nil))
    }

    public func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {

        guard let url = webView.url else {
            return
        }

        // WeChat OAuth
        if url.absoluteString.hasPrefix("wx") {
            
            let queryDictionary = url.monkeyking_queryDictionary
            guard let code = queryDictionary["code"] as? String else {
                return
            }
            
            MonkeyKing.fetchWeChatOAuthInfoByCode(code: code) { [weak self] (info, response, error) -> Void in
                self?.removeWebView(webView, tuples: (info, response, error))
            }
            
        } else {
            
            // Weibo OAuth
            for case let .weibo(appID, appKey, redirectURL) in accountSet {
                if url.absoluteString.lowercased().hasPrefix(redirectURL) {
                    
                    webView.stopLoading()
                    
                    guard let code = url.monkeyking_queryDictionary["code"] as? String else {
                        return
                    }
                    
                    var accessTokenAPI = "https://api.weibo.com/oauth2/access_token?"
                    accessTokenAPI += "client_id=" + appID
                    accessTokenAPI += "&client_secret=" + appKey
                    accessTokenAPI += "&grant_type=authorization_code"
                    accessTokenAPI += "&redirect_uri=" + redirectURL
                    accessTokenAPI += "&code=" + code
                    
                    activityIndicatorViewAction(webView, stop: false)
                    
                    request(accessTokenAPI, method: .post) { [weak self] (json, response, error) -> Void in
                        DispatchQueue.main.async {
                            self?.removeWebView(webView, tuples: (json, response, error))
                        }
                    }
                }
            }
        }
    }
}


// MARK: Private Methods

extension MonkeyKing {
    
    fileprivate class func generateWebView() -> WKWebView {
        
        let webView = WKWebView()
        webView.frame = UIScreen.main.bounds
        webView.frame.origin.y = UIScreen.main.bounds.height
        
        webView.navigationDelegate = sharedMonkeyKing
        webView.backgroundColor = UIColor(red: 247/255, green: 247/255, blue: 247/255, alpha: 1.0)
        webView.scrollView.frame.origin.y = 20
        webView.scrollView.backgroundColor = webView.backgroundColor
        
        UIApplication.shared.keyWindow?.addSubview(webView)
        
        return webView
    }

    fileprivate class func fetchWeChatOAuthInfoByCode(code: String, completionHandler: @escaping OAuthCompletionHandler) {

        var appID = ""
        var appKey = ""
        for case let .weChat(id, key) in sharedMonkeyKing.accountSet {

            guard let key = key else {
                completionHandler(["code": code], nil, nil)
                return
            }

            appID = id
            appKey = key
        }

        var accessTokenAPI = "https://api.weixin.qq.com/sns/oauth2/access_token?"
        accessTokenAPI += "appid=" + appID
        accessTokenAPI += "&secret=" + appKey
        accessTokenAPI += "&code=" + code + "&grant_type=authorization_code"

        // OAuth
        sharedMonkeyKing.request(accessTokenAPI, method: .get) { (json, response, error) -> Void in
            completionHandler(json, response, error)
        }
    }

    fileprivate class func createAlipayMessageDictionary(info: Info, appID: String) -> NSDictionary {

        enum AlipayMessageType {
            case text
            case image(UIImage)
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
            case .audio:
                fatalError("Alipay not supports Audio type")
            case .video:
                fatalError("Alipay not supports Video type")
            case .file:
                fatalError("Alipay not supports File type")
            }
        } else { // Text
            messageType = .text
        }

        // Public Items
        let UIDValue: Int
        let APMediaType: String

        switch messageType {
        case .text:
            UIDValue = 19
            APMediaType = "APShareTextObject"
        case .image:
            UIDValue = 20
            APMediaType = "APShareImageObject"
        case .url:
            UIDValue = 23
            APMediaType = "APShareWebObject"
        }

        let publicObjectsItem0 = "$null"
        let publicObjectsItem1: NSDictionary = [
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
        let publicObjectsItem4: NSDictionary = [
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
        let publicObjectsItem9 = "1.0.1.150917" // SDK Version
        let publicObjectsItem10: NSDictionary = [
            keyClasses: ["APSdkApp", "NSObject"],
            keyClassname: "APSdkApp"
        ]
        let publicObjectsItem11: NSDictionary = [
            keyClass: [keyUID: UIDValue - 1],
            "message": [keyUID: 13],
            "scene": [keyUID: 12],
            "type": [keyUID: 12]
        ]
        let publicObjectsItem12: NSNumber = 0
        let publicObjectsItem13: NSDictionary = [    // For Text(13) && Image(13)
            keyClass: [keyUID: UIDValue - 2],
            "mediaObject": [keyUID: 14]
        ]
        let publicObjectsItem14: NSDictionary = [   // For Image(16) && URL(17)
            keyClasses: ["NSMutableData", "NSData", "NSObject"],
            keyClassname: "NSMutableData"
        ]
        let publicObjectsItem16: NSDictionary = [
            keyClasses: [APMediaType, "NSObject"],
            keyClassname: APMediaType
        ]
        let publicObjectsItem17: NSDictionary = [
            keyClasses: ["APMediaMessage", "NSObject"],
            keyClassname: "APMediaMessage"
        ]
        let publicObjectsItem18: NSDictionary = [
            keyClasses: ["APSendMessageToAPReq", "APBaseReq", "NSObject"],
            keyClassname: "APSendMessageToAPReq"
        ]
        let publicObjectsItem19: NSDictionary = [
            keyClasses: ["NSMutableDictionary", "NSDictionary", "NSObject"],
            keyClassname: "NSMutableDictionary"
        ]

        var objectsValue = [
            publicObjectsItem0, publicObjectsItem1, publicObjectsItem2, publicObjectsItem3,
            publicObjectsItem4, publicObjectsItem5, publicObjectsItem6, publicObjectsItem7,
            publicObjectsItem8, publicObjectsItem9, publicObjectsItem10, publicObjectsItem11,
            publicObjectsItem12
        ] as [Any]

        switch messageType {
        case .text:
            let textObjectsItem14: NSDictionary = [
                keyClass: [keyUID: 16],
                "text": [keyUID: 15]
            ]

            let textObjectsItem15 = info.title ?? "Input Text"
            objectsValue = objectsValue + [publicObjectsItem13, textObjectsItem14, textObjectsItem15]

        case .image(let image):
            let imageObjectsItem14: NSDictionary = [
                keyClass: [keyUID: 17],
                "imageData": [keyUID: 15]
            ]

            let imageData = UIImageJPEGRepresentation(image, 0.7) ?? Data()
            let imageObjectsItem15: NSDictionary = [
                keyClass: [keyUID: 16],
                "NS.data": imageData
            ]
            objectsValue = objectsValue + [publicObjectsItem13, imageObjectsItem14, imageObjectsItem15, publicObjectsItem14]

        case .url(let url):
            let urlObjectsItem13: NSDictionary = [
                keyClass: [keyUID: 21],
                "desc": [keyUID: 15],
                "mediaObject": [keyUID: 18],
                "thumbData": [keyUID: 16],
                "title": [keyUID: 14]
            ]

            let thumbnailData = info.thumbnail?.monkeyking_compressedImageData ?? Data()

            let urlObjectsItem14 = info.title ?? "Input Title"
            let urlObjectsItem15 = info.description ?? "Input Description"
            let urlObjectsItem16: NSDictionary = [
                keyClass: [keyUID: 17],
                "NS.data": thumbnailData
            ]
            let urlObjectsItem18: NSDictionary = [
                keyClass: [keyUID: 20],
                "webpageUrl": [keyUID: 19]
            ]
            let urlObjectsItem19 = url.absoluteString
            objectsValue = objectsValue + [
                urlObjectsItem13, urlObjectsItem14, urlObjectsItem15,
                urlObjectsItem16, publicObjectsItem14, urlObjectsItem18, urlObjectsItem19
            ]
        }

        objectsValue += [publicObjectsItem16, publicObjectsItem17, publicObjectsItem18, publicObjectsItem19]

        let dictionary: NSDictionary = [
            "$archiver": "NSKeyedArchiver",
            "$objects": objectsValue,
            "$top": ["root" : [keyUID: 1]],
            "$version": 100000
        ]
        
        return dictionary
    }

    fileprivate func request(_ urlString: String, method: Networking.Method, parameters: [String: AnyObject]? = nil, encoding: Networking.ParameterEncoding = .url, headers: [String: String]? = nil, completionHandler: @escaping Networking.NetworkingResponseHandler) {

        Networking.sharedInstance.request(urlString, method: method, parameters: parameters, encoding: encoding, headers: headers, completionHandler: completionHandler)
    }

    fileprivate func upload(_ urlString: String, parameters: [String: AnyObject], completionHandler: @escaping Networking.NetworkingResponseHandler) {

        Networking.sharedInstance.upload(urlString, parameters: parameters, completionHandler: completionHandler)
    }

    fileprivate class func addWebView(withURLString urlString: String) {
        
        if nil == MonkeyKing.sharedMonkeyKing.webView {
            MonkeyKing.sharedMonkeyKing.webView = generateWebView()
        }

        guard let url = URL(string: urlString), let webView = MonkeyKing.sharedMonkeyKing.webView else {
            return
        }
        
        webView.load(URLRequest(url: url))
        
        let activityIndicatorView = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        activityIndicatorView.center = CGPoint(x: webView.bounds.midX, y: webView.bounds.midY+30)
        activityIndicatorView.activityIndicatorViewStyle = .gray

        webView.scrollView.addSubview(activityIndicatorView)
        activityIndicatorView.startAnimating()

        UIView.animate(withDuration: 0.32, delay: 0.0, options: .curveEaseOut, animations: {
            webView.frame.origin.y = 0
        }, completion: nil)
    }

    fileprivate func removeWebView(_ webView: WKWebView, tuples: (NSDictionary?, URLResponse?, NSError?)?) {

        activityIndicatorViewAction(webView, stop: true)
        webView.stopLoading()

        UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseOut, animations: {
            webView.frame.origin.y = UIScreen.main.bounds.height

        }, completion: {_ in
            webView.removeFromSuperview()
            MonkeyKing.sharedMonkeyKing.webView = nil
            self.oauthCompletionHandler?(tuples?.0, tuples?.1, tuples?.2)
        })
    }

    fileprivate func activityIndicatorViewAction(_ webView: WKWebView, stop: Bool) {

        for subview in webView.scrollView.subviews {
            if let activityIndicatorView = subview as? UIActivityIndicatorView {
                guard stop else {
                    activityIndicatorView.startAnimating()
                    return
                }
                activityIndicatorView.stopAnimating()
            }
        }
    }

    fileprivate class func openURL(urlString: String) -> Bool {

        guard let url = URL(string: urlString) else {
            return false
        }

        return UIApplication.shared.openURL(url)
    }

    fileprivate func canOpenURL(urlString: String) -> Bool {

        guard let url = URL(string: urlString) else {
            return false
        }

        return UIApplication.shared.canOpenURL(url)
    }
}


// MARK: Private Extensions

private extension Set {

    subscript(platform: MonkeyKing.SupportedPlatform) -> MonkeyKing.Account? {

        let accountSet = MonkeyKing.sharedMonkeyKing.accountSet

        switch platform {

        case .weChat:
            for account in accountSet {
                if case .weChat = account {
                    return account
                }
            }
        case .qq:
            for account in accountSet {
                if case .qq = account {
                    return account
                }
            }
        case .weibo:
            for account in accountSet {
                if case .weibo = account {
                    return account
                }
            }
        case .pocket:
            for account in accountSet {
                if case .pocket = account {
                    return account
                }
            }
        case .alipay:
            for account in accountSet {
                if case .alipay = account {
                    return account
                }
            }
        }
        
        return nil
    }

    subscript(platform: MonkeyKing.Message) -> MonkeyKing.Account? {

        let accountSet = MonkeyKing.sharedMonkeyKing.accountSet

        switch platform {

        case .weChat:
            for account in accountSet {
                if case .weChat = account {
                    return account
                }
            }
        case .qq:
            for account in accountSet {
                if case .qq = account {
                    return account
                }
            }
        case .weibo:
            for account in accountSet {
                if case .weibo = account {
                    return account
                }
            }
        case .alipay:
            for account in accountSet {
                if case .alipay = account {
                    return account
                }
            }
        }

        return nil
    }
}

private extension Bundle {

    var monkeyking_displayName: String? {

        func getNameByInfo(_ info: [String : AnyObject]) -> String? {

            guard let displayName = info["CFBundleDisplayName"] as? String else {
                return info["CFBundleName"] as? String
            }

            return displayName
        }

        var info = infoDictionary

        if let localizedInfo = localizedInfoDictionary, !localizedInfo.isEmpty {
            info = localizedInfo
        }

        guard let unwrappedInfo = info else {
            return nil
        }

        return getNameByInfo(unwrappedInfo as [String : AnyObject])
    }

    var monkeyking_bundleID: String? {
        return object(forInfoDictionaryKey: "CFBundleIdentifier") as? String
    }
}

private extension String {

    var monkeyking_base64EncodedString: String? {
        return data(using: String.Encoding.utf8)?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
    }

    var monkeyking_urlEncodedString: String? {
        return addingPercentEncoding(withAllowedCharacters: CharacterSet.urlHostAllowed)
    }

    var monkeyking_base64AndURLEncodedString: String? {
        return monkeyking_base64EncodedString?.monkeyking_urlEncodedString
    }
    
    var monkeyking_urlDecodedString: String? {
        return replacingOccurrences(of: "+", with: " ").removingPercentEncoding
    }

    var monkeyking_qqCallbackName: String {

        var hexString = String(format: "%02llx", (self as NSString).longLongValue)
        while hexString.characters.count < 8 {
            hexString = "0" + hexString
        }

        return "QQ" + hexString
    }
}

private extension Data {

    var monkeyking_json: [String: AnyObject]? {
        do {
            return try JSONSerialization.jsonObject(with: self, options: .allowFragments) as? [String: AnyObject]
        } catch {
            return nil
        }
    }
}

private extension URL {

    var monkeyking_queryDictionary: [String: AnyObject] {

        var infos = [String: AnyObject]()

        let components = URLComponents(url: self, resolvingAgainstBaseURL: false)

        guard let items = components?.queryItems else {
            return infos
        }

        items.forEach {
            infos[$0.name] = $0.value as AnyObject?
        }

        return infos
    }
}

private extension UIImage {

    var monkeyking_compressedImageData: Data? {

        var compressionQuality: CGFloat = 0.7

        func compresseImage(_ image: UIImage) -> Data? {

            let maxHeight: CGFloat = 240.0
            let maxWidth: CGFloat = 240.0
            var actualHeight: CGFloat = image.size.height
            var actualWidth: CGFloat = image.size.width
            var imgRatio: CGFloat = actualWidth/actualHeight
            let maxRatio: CGFloat = maxWidth/maxHeight

            if actualHeight > maxHeight || actualWidth > maxWidth {

                if imgRatio < maxRatio { // adjust width according to maxHeight

                    imgRatio = maxHeight / actualHeight
                    actualWidth = imgRatio * actualWidth
                    actualHeight = maxHeight

                } else if imgRatio > maxRatio { // adjust height according to maxWidth

                    imgRatio = maxWidth / actualWidth
                    actualHeight = imgRatio * actualHeight
                    actualWidth = maxWidth

                } else {
                    actualHeight = maxHeight
                    actualWidth = maxWidth
                }
            }

            let rect = CGRect(x: 0.0, y: 0.0, width: actualWidth, height: actualHeight)
            UIGraphicsBeginImageContext(rect.size)
            defer {
                UIGraphicsEndImageContext()
            }
            image.draw(in: rect)

            let imageData = UIGraphicsGetImageFromCurrentImageContext().flatMap({
                UIImageJPEGRepresentation($0, compressionQuality)
            })
            return imageData
        }

        var imageData = UIImageJPEGRepresentation(self, compressionQuality)

        guard imageData != nil else {
            return nil
        }

        let minCompressionQuality: CGFloat = 0.01
        let dataLengthCeiling: Int = 31500

        while imageData!.count > dataLengthCeiling && compressionQuality > minCompressionQuality {
            compressionQuality -= 0.1
            guard let image = UIImage(data: imageData!) else {
                break
            }
            imageData = compresseImage(image)
        }
        
        return imageData
    }
}

