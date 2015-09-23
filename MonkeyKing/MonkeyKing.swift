//
//  MonkeyKing.swift
//  MonkeyKing
//
//  Created by NIX on 15/9/11.
//  Copyright © 2015年 nixWork. All rights reserved.
//

import UIKit

public func ==(lhs: MonkeyKing.Account, rhs: MonkeyKing.Account) -> Bool {
    return lhs.appID == rhs.appID
}

public class MonkeyKing {

    static let sharedMonkeyKing = MonkeyKing()

    public enum Account: Hashable {

        case WeChat(appID: String, appKey: String)
        case QQ(appID: String)
        case Weibo(appID: String)

        func canOpenURL(URL: NSURL?) -> Bool {
            guard let URL = URL else {
                return false
            }
            return UIApplication.sharedApplication().canOpenURL(URL)
        }

        public var isAppInstalled: Bool {
            switch self {
            case .WeChat:
                return canOpenURL(NSURL(string: "weixin://"))
            case .QQ:
                return canOpenURL(NSURL(string: "mqqapi://"))
            case .Weibo:
                return canOpenURL(NSURL(string: "weibosdk://request"))
            }
        }

        public var appID: String {
            switch self {
            case .WeChat(let appID, _):
                return appID
            case .QQ(let appID):
                return appID
            case .Weibo(let appID):
                return appID
            }
        }

        public var hashValue: Int {
            return appID.hashValue
        }
    }

    var accountSet = Set<Account>()

    public class func registerAccount(account: Account) {

        if account.isAppInstalled {
            sharedMonkeyKing.accountSet.insert(account)
        }
    }

    public class func handleOpenURL(URL: NSURL) -> Bool {

        if URL.scheme.hasPrefix("wx") {

            // WeChat OAuth
            if let stateRange = URL.absoluteString.rangeOfString("&state=Weixinauth"),
                let codeRange = URL.absoluteString.rangeOfString("?code=") {
                    //login succcess
                    let code = URL.absoluteString.substringToIndex(stateRange.startIndex).substringFromIndex(codeRange.endIndex)
                    fetchUserInfoByCode(code: code) { (userInfo, response, error) -> Void in
                        sharedMonkeyKing.oauthCompletionHandler?(userInfo, response, error)
                    }
                    return true
            }

            // WeChat Share
            guard let data = UIPasteboard.generalPasteboard().dataForPasteboardType("content") else {
                return false
            }

            if let dic = try? NSPropertyListSerialization.propertyListWithData(data, options: .Immutable, format: nil) {

                for case let .WeChat(appID, _) in sharedMonkeyKing.accountSet {

                    if let dic = dic[appID] as? NSDictionary {

                        if let result = dic["result"]?.integerValue {

                            let success = (result == 0)

                            sharedMonkeyKing.latestFinish?(success)

                            return success
                        }
                    }
                }
            }
        }

        if URL.scheme.hasPrefix("QQ") {
            // QQ Share
            guard let error = URL.queryInfo["error"] else {
                return false
            }

            let success = (error == "0")

            sharedMonkeyKing.latestFinish?(success)

            return success
        }

        if URL.scheme.hasPrefix("tencent") {
            // QQ OAuth
            for case let .QQ(appID) in sharedMonkeyKing.accountSet {

                var userInfoDictionary: NSDictionary?
                var error: NSError?

                defer {
                    sharedMonkeyKing.oauthCompletionHandler?(userInfoDictionary, nil, error)
                }

                guard let data = UIPasteboard.generalPasteboard().dataForPasteboardType("com.tencent.tencent\(appID)"),
                    let dic = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? NSDictionary else {
                        error = NSError(domain: "OAuth Error", code: 0, userInfo: nil)
                        return false
                }

                guard let result = dic["ret"]?.integerValue where result != 0 else {
                    if let errorDomatin = dic["user_cancelled"] as? String where errorDomatin == "YES" {
                        error = NSError(domain: "User Cancelled", code: -1, userInfo: nil)
                    } else {
                        error = NSError(domain: "OAuth Error", code: 0, userInfo: nil)
                    }
                    return false
                }

                userInfoDictionary = dic

                return true
            }
        }


        return false
    }

    public enum Media {
        case URL(NSURL)
        case Image(UIImage)
    }

    public typealias Info = (title: String?, description: String?, thumbnail: UIImage?, media: Media)

    public enum Message {

        public enum WeChatSubtype {

            case Session(info: Info)
            case Timeline(info: Info)

            var scene: String {
                switch self {
                case .Session:
                    return "0"
                case .Timeline:
                    return "1"
                }
            }

            var info: Info {
                switch self {
                case .Session(let info):
                    return info
                case .Timeline(let info):
                    return info
                }
            }
        }
        case WeChat(WeChatSubtype)

        public enum QQSubtype {
            case Friends(info: Info)
            case QZone(info: Info)

            var scene: Int {
                switch self {
                case .Friends:
                    return 0
                case .QZone:
                    return 1
                }
            }

            var info: Info {
                switch self {
                case .Friends(let info):
                    return info
                case .QZone(let info):
                    return info
                }
            }
        }
        case QQ(QQSubtype)

        public enum WeiboSubtype {
            case Default(info: Info)

            var info: Info {
                switch self {
                case .Default(let info):
                    return info
                }
            }
        }
        case Weibo(WeiboSubtype)

        public var canBeDelivered: Bool {

            switch self {

            case .WeChat:
                for account in sharedMonkeyKing.accountSet {
                    if case .WeChat = account {
                        return account.isAppInstalled
                    }
                }
                return false

            case .QQ:
                for account in sharedMonkeyKing.accountSet {
                    if case .QQ = account {
                        return account.isAppInstalled
                    }
                }
                return false
            case .Weibo:
                for account in sharedMonkeyKing.accountSet {
                    if case .Weibo = account {
                        return account.isAppInstalled
                    }
                }
                return false
            }
        }
    }

    public typealias Finish = Bool -> Void
    var latestFinish: Finish?

    private var oauthCompletionHandler: SerializeResponse?

    private class func openURL(URLString: String) {
        guard let URL = NSURL(string: URLString) else {
            return
        }
        UIApplication.sharedApplication().openURL(URL)
    }

    public class func shareMessage(message: Message, finish: Finish) {

        guard message.canBeDelivered else {
            finish(false)
            return
        }

        sharedMonkeyKing.latestFinish = finish

        switch message {

        case .WeChat(let type):

            for case let .WeChat(appID, _) in sharedMonkeyKing.accountSet {

                var weChatMessageInfo: [String: AnyObject] = [
                    "result": "1",
                    "returnFromApp": "0",
                    "scene": type.scene,
                    "sdkver": "1.5",
                    "command": "1010",
                ]

                let info = type.info

                if let title = info.title {
                    weChatMessageInfo["title"] = title
                }

                if let description = info.description {
                    weChatMessageInfo["description"] = description
                }

                if let thumbnailImage = info.thumbnail,
                    let thumbnailData = UIImageJPEGRepresentation(thumbnailImage, 0.7) {
                        weChatMessageInfo["thumbData"] = thumbnailData
                }

                switch info.media {

                case .URL(let URL):
                    weChatMessageInfo["objectType"] = "5"
                    weChatMessageInfo["mediaUrl"] = URL.absoluteString

                case .Image(let image):
                    weChatMessageInfo["objectType"] = "2"

                    if let fileImageData = UIImageJPEGRepresentation(image, 1) {
                        weChatMessageInfo["fileData"] = fileImageData
                    }
                }

                let weChatMessage = [appID: weChatMessageInfo]

                guard let data = try? NSPropertyListSerialization.dataWithPropertyList(weChatMessage, format: .BinaryFormat_v1_0, options: 0) else {
                    return
                }

                UIPasteboard.generalPasteboard().setData(data, forPasteboardType: "content")

                let weChatSchemeURLString = "weixin://app/\(appID)/sendreq/?"

                guard let URL = NSURL(string: weChatSchemeURLString) else {
                    return
                }

                if !UIApplication.sharedApplication().openURL(URL) {
                    finish(false)
                }
            }

        case .QQ(let type):

            for case let .QQ(appID) in sharedMonkeyKing.accountSet {

                let callbackName = String(format: "QQ%02llx", (appID as NSString).longLongValue)

                print(NSBundle.mainBundle().displayName!)

                var qqSchemeURLString = "mqqapi://share/to_fri?"
                if let encodedAppDisplayName = NSBundle.mainBundle().displayName?.base64EncodedString {
                    qqSchemeURLString += "thirdAppDisplayName=" + encodedAppDisplayName
                } else {
                    qqSchemeURLString += "thirdAppDisplayName=" + "nixApp" // Should not be there
                }

                qqSchemeURLString += "&version=1&cflag=\(type.scene)"
                qqSchemeURLString += "&callback_type=scheme&generalpastboard=1"
                qqSchemeURLString += "&callback_name=\(callbackName)"

                if let encodedTitle = type.info.title?.base64AndURLEncodedString {
                    qqSchemeURLString += "&title=\(encodedTitle)"
                }

                if let encodedDescription = type.info.description?.base64AndURLEncodedString {
                    qqSchemeURLString += "&objectlocation=pasteboard&description=\(encodedDescription)"
                }

                qqSchemeURLString+="&src_type=app&shareType=0&file_type="

                switch type.info.media {

                case .URL(let URL):

                    if let thumbnail = type.info.thumbnail, thumbnailData = UIImageJPEGRepresentation(thumbnail, 1) {
                        let dic = ["previewimagedata": thumbnailData]
                        let data = NSKeyedArchiver.archivedDataWithRootObject(dic)
                        UIPasteboard.generalPasteboard().setData(data, forPasteboardType: "com.tencent.mqq.api.apiLargeData")
                    }

                    qqSchemeURLString += "news"

                    guard let encodedURLString = URL.absoluteString.base64AndURLEncodedString else {
                        finish(false)
                        return
                    }

                    qqSchemeURLString += "&url=\(encodedURLString)"

                case .Image(let image):

                    guard let imageData = UIImageJPEGRepresentation(image, 1) else {
                        finish(false)
                        return
                    }

                    var dic = [
                        "file_data": imageData,
                    ]
                    if let thumbnail = type.info.thumbnail, thumbnailData = UIImageJPEGRepresentation(thumbnail, 1) {
                        dic["previewimagedata"] = thumbnailData
                    }

                    let data = NSKeyedArchiver.archivedDataWithRootObject(dic)

                    UIPasteboard.generalPasteboard().setData(data, forPasteboardType: "com.tencent.mqq.api.apiLargeData")

                    qqSchemeURLString += "img"
                }

                guard let URL = NSURL(string: qqSchemeURLString) else {
                    return
                }

                if !UIApplication.sharedApplication().openURL(URL) {
                    finish(false)
                }
            }

        case .Weibo(let type):
            for case let .Weibo(appID) in sharedMonkeyKing.accountSet {

                var messageInfo: [String: AnyObject] = ["__class": "WBMessageObject"]
                let info = type.info

                switch type.info.media {
                case .URL(let URL):

                    var mediaObject: [String: AnyObject] = [
                        "__class": "WBWebpageObject",
                        "objectID": "identifier1"
                    ]

                    if let title = info.title {
                        mediaObject["title"] = title
                    }

                    if let description = info.description {
                        messageInfo["text"] = description
                    }

                    if let thumbnailImage = info.thumbnail,
                        let thumbnailData = UIImageJPEGRepresentation(thumbnailImage, 0.7) {
                            mediaObject["thumbnailData"] = thumbnailData
                    }

                    mediaObject["webpageUrl"] = URL.absoluteString

                    messageInfo["mediaObject"] = mediaObject

                case .Image(let image):

                    if let title = info.title {
                        messageInfo["text"] = title
                    }

                    if let imageData = UIImageJPEGRepresentation(image, 1.0) {
                        messageInfo["imageObject"] = ["imageData": imageData]
                    }
                }

                let uuIDString = CFUUIDCreateString(nil, CFUUIDCreate(nil))
                let dict = ["__class" : "WBSendMessageToWeiboRequest", "message": messageInfo, "requestID" :uuIDString]

                let messageData: [AnyObject] = [
                    ["transferObject": NSKeyedArchiver.archivedDataWithRootObject(dict)],
                    ["userInfo": NSKeyedArchiver.archivedDataWithRootObject([])],
                    ["app": NSKeyedArchiver.archivedDataWithRootObject(["appKey": appID, "bundleID": NSBundle.mainBundle().bundleID ?? ""])]
                ]

                UIPasteboard.generalPasteboard().items = messageData
                openURL("weibosdk://request?id=\(uuIDString)&sdkversion=003013000")
            }

        }
    }
}

// MARK: OAuth

extension MonkeyKing {

    public typealias SerializeResponse = (NSDictionary?, NSURLResponse?, NSError?) -> Void

    public class func OAuth(account: Account, completionHandler: SerializeResponse) {

        guard account.isAppInstalled else {
            var errorDomain = "App is not installed"
            for account in sharedMonkeyKing.accountSet {
                if case .WeChat = account {
                    errorDomain += "WeChat "
                }
            }
            let error = NSError(domain: errorDomain, code: 0, userInfo: nil)
            completionHandler(nil, nil, error)
            return
        }

        sharedMonkeyKing.oauthCompletionHandler = completionHandler

        switch account {

            case .WeChat(let appID):
                let scope = "snsapi_userinfo"
                openURL("weixin://app/\(appID)/auth/?scope=\(scope)&state=Weixinauth")

            case .QQ(let appID):
                let scope = ""
                let appName = NSBundle.mainBundle().displayName ?? "nixApp"
                let dic = ["app_id": appID,
                    "app_name": appName,
                    "client_id": appID,
                    "response_type":"token",
                    "scope":scope,
                    "sdkp":"i",
                    "sdkv":"2.9",
                    "status_machine": UIDevice.currentDevice().model,
                    "status_os": UIDevice.currentDevice().systemVersion,
                    "status_version": UIDevice.currentDevice().systemVersion]

                let data = NSKeyedArchiver.archivedDataWithRootObject(dic)
                UIPasteboard.generalPasteboard().setData(data, forPasteboardType: "com.tencent.tencent\(appID)")

                openURL("mqqOpensdkSSoLogin://SSoLogin/tencent\(appID)/com.tencent.tencent\(appID)?generalpastboard=1")

            case .Weibo(let appID):
                break
        }
    }

    private class func fetchUserInfoByCode(code code: String, completionHandler: SerializeResponse) {

        var appID = ""
        var appKey = ""
        for case let .WeChat(id, key) in sharedMonkeyKing.accountSet {
            appID = id
            appKey = key
        }

        var accessTokenAPI = "https://api.weixin.qq.com/sns/oauth2/access_token?"
        accessTokenAPI += "appid=" + appID
        accessTokenAPI += "&secret=" + appKey
        accessTokenAPI += "&code=" + code + "&grant_type=authorization_code"

        guard let URL = NSURL(string: accessTokenAPI) else {
            return
        }

        // OAuth
        sendRequest(URL) { (OAuthJSON, response, error) -> Void in

            var userInfoDictionary: NSDictionary?

            guard let accessToken = OAuthJSON?["access_token"] as? String,
                let openID = OAuthJSON?["openid"] as? String,
                let refreshToken = OAuthJSON?["refresh_token"] as? String,
                let expiresIn = OAuthJSON?["expires_in"] as? Int else {
                    completionHandler(userInfoDictionary, response, error)
                    return
            }

            let userInfoAPI = "https://api.weixin.qq.com/sns/userinfo?access_token=\(accessToken)&openid=\(openID)"
            guard let URL = NSURL(string: userInfoAPI) else {
                return
            }

            // fetch UserInfo
            sendRequest(URL) { (userInfoJSON, response, error) -> Void in

                defer {
                    completionHandler(userInfoDictionary, response, error)
                }

                guard let userInfoJSON = userInfoJSON,
                    let mutableDictionary = userInfoJSON.mutableCopy() as? NSMutableDictionary else {
                        return
                }

                mutableDictionary["access_token"] = accessToken
                mutableDictionary["openid"] = openID
                mutableDictionary["refresh_token"] = refreshToken
                mutableDictionary["expires_in"] = expiresIn
                
                userInfoDictionary = mutableDictionary
            }
        }
    }
    
    private class func sendRequest(URL: NSURL, completionHandler: SerializeResponse) {
        
        let session = NSURLSession.sharedSession()
        let request = NSMutableURLRequest(URL: URL)
        request.HTTPMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) -> Void in
            
            var JSON: NSDictionary?
            
            defer {
                completionHandler(JSON, response, error)
            }
            
            guard let httpResponse = response as? NSHTTPURLResponse where httpResponse.statusCode == 200 else {
                print("No Success HTTP Response Status Code")
                return
            }
            
            guard let validData = data,
                let JSONData = try? NSJSONSerialization.JSONObjectWithData(validData, options: .AllowFragments) as? NSDictionary else {
                    print("JSON could not be serialized because input data was nil.")
                    return
            }
            
            JSON = JSONData
        }
        
        task.resume()
    }
    
}


// MARK: Private Extensions

private extension NSBundle {

    var displayName: String? {

        if let info = infoDictionary {

            if let localizedDisplayName = info["CFBundleDisplayName"] as? String {
                return localizedDisplayName

            } else {
                return info["CFBundleName"] as? String
            }
        }

        return nil
    }

    var bundleID: String? {
        return objectForInfoDictionaryKey("CFBundleIdentifier") as? String
    }
}

private extension String {

    var base64EncodedString: String? {
        return dataUsingEncoding(NSUTF8StringEncoding)?.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
    }

    var urlEncodedString: String? {
        return stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet())
    }

    var base64AndURLEncodedString: String? {
        return base64EncodedString?.urlEncodedString
    }
}

private extension NSURL {

    var queryInfo: [String: String] {

        var info = [String: String]()

        if let querys = query?.componentsSeparatedByString("&") {
            for query in querys {
                let keyValuePair = query.componentsSeparatedByString("=")
                if keyValuePair.count == 2 {
                    let key = keyValuePair[0]
                    let value = keyValuePair[1]

                    info[key] = value
                }
            }
        }
        
        return info
    }
}
