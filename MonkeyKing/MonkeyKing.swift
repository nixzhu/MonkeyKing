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

public class MonkeyKing: NSObject {

    static let sharedMonkeyKing = MonkeyKing()

    public enum Account: Hashable {

        case WeChat(appID: String, appKey: String)
        case QQ(appID: String)
        case Weibo(appID: String, appKey: String, redirectURL: String)

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
            case .Weibo(let appID, _, _):
                return appID
            }
        }

        public var hashValue: Int {
            return appID.hashValue
        }

        public var isWeiboAccount: Bool {
            switch self {
            case .Weibo:
                return true
            default:
                return false
            }
        }
    }

    var accountSet = Set<Account>()

    public class func registerAccount(account: Account) {

        if account.isAppInstalled {
            sharedMonkeyKing.accountSet.insert(account)

        } else if case .Weibo = account {
            sharedMonkeyKing.accountSet.insert(account)
        }

    }

    public class func handleOpenURL(URL: NSURL) -> Bool {

        if URL.scheme.hasPrefix("wx") {

            // WeChat OAuth
            if let stateRange = URL.absoluteString.rangeOfString("&state=Weixinauth") {
                if let codeRange = URL.absoluteString.rangeOfString("?code=") {
                    //login succcess
                    let code = URL.absoluteString.substringToIndex(stateRange.startIndex).substringFromIndex(codeRange.endIndex)
                    fetchWeChatUserInfoByCode(code: code) { (userInfo, response, error) -> Void in
                        sharedMonkeyKing.oauthCompletionHandler?(userInfo, response, error)
                    }
                    return true
                }
                return false
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
        
        // QQ Share
        if URL.scheme.hasPrefix("QQ") {

            guard let error = URL.queryInfo["error"] else {
                return false
            }

            let success = (error == "0")

            sharedMonkeyKing.latestFinish?(success)

            return success
        }

        // QQ OAuth
        if URL.scheme.hasPrefix("tencent") {

            for case let .QQ(appID) in sharedMonkeyKing.accountSet {

                var userInfoDictionary: NSDictionary?
                var error: NSError?

                defer {
                    sharedMonkeyKing.oauthCompletionHandler?(userInfoDictionary, nil, error)
                }

                guard let data = UIPasteboard.generalPasteboard().dataForPasteboardType("com.tencent.tencent\(appID)"),
                    let dic = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? NSDictionary else {
                        error = NSError(domain: "OAuth Error", code: -1, userInfo: nil)
                        return false
                }

                guard let result = dic["ret"]?.integerValue where result == 0 else {
                    if let errorDomatin = dic["user_cancelled"] as? String where errorDomatin == "YES" {
                        error = NSError(domain: "User Cancelled", code: -2, userInfo: nil)
                    } else {
                        error = NSError(domain: "OAuth Error", code: -1, userInfo: nil)
                    }
                    return false
                }

                userInfoDictionary = dic

                return true
            }
        }

        // Weibo
        if URL.scheme.hasPrefix("wb") {
            guard let items = UIPasteboard.generalPasteboard().items as? [[String: AnyObject]] else {
                return false
            }
            var results = [String: AnyObject]()

            for item in items {
                for (key, value) in item {
                    if let valueData = value as? NSData where key == "transferObject" {
                        results[key] = NSKeyedUnarchiver.unarchiveObjectWithData(valueData)
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
                        sharedMonkeyKing.oauthCompletionHandler?(responseData, nil, error)
                    }

                    userInfoDictionary = responseData

                    if statusCode != 0 {
                        error = NSError(domain: "OAuth Error", code: -1, userInfo: nil)
                        return false
                    }
                    return true

                // Weibo Share
                case "WBSendMessageToWeiboResponse":

                    let success = (statusCode == 0)
                    sharedMonkeyKing.latestFinish?(success)

                    return success

                default:
                    break
            }

        }

        return false
    }

    public enum Media {
        case URL(NSURL)
        case Image(UIImage)
    }

    public typealias Info = (title: String?, description: String?, thumbnail: UIImage?, media: Media?)

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
            case Zone(info: Info)

            var scene: Int {
                switch self {
                case .Friends:
                    return 0
                case .Zone:
                    return 1
                }
            }

            var info: Info {
                switch self {
                case .Friends(let info):
                    return info
                case .Zone(let info):
                    return info
                }
            }
        }
        case QQ(QQSubtype)

        public enum WeiboSubtype {
            case Default(info: Info, accessToken: String?)

            var info: Info {
                switch self {
                    case .Default(let info, _):
                        return info
                    }
            }

            var accessToken: String? {
                switch self {
                    case .Default(_, let accessToken):
                        return accessToken
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
                return true
            }
        }
    }

    public typealias Finish = Bool -> Void
    var latestFinish: Finish?

    private var oauthCompletionHandler: SerializeResponse?

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
                    let thumbnailData = UIImageJPEGRepresentation(thumbnailImage, 0.5) {
                        weChatMessageInfo["thumbData"] = thumbnailData
                }

                if let media = info.media {
                    switch media {

                        case .URL(let URL):
                            weChatMessageInfo["objectType"] = "5"
                            weChatMessageInfo["mediaUrl"] = URL.absoluteString

                        case .Image(let image):
                            weChatMessageInfo["objectType"] = "2"

                            if let fileImageData = UIImageJPEGRepresentation(image, 1) {
                                weChatMessageInfo["fileData"] = fileImageData
                            }
                    }

                } else { // Text Share

                    weChatMessageInfo["command"] = "1020"
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

                var qqSchemeURLString = "mqqapi://share/to_fri?"
                if let encodedAppDisplayName = NSBundle.mainBundle().displayName?.base64EncodedString {
                    qqSchemeURLString += "thirdAppDisplayName=" + encodedAppDisplayName
                } else {
                    qqSchemeURLString += "thirdAppDisplayName=" + "nixApp" // Should not be there
                }

                qqSchemeURLString += "&version=1&cflag=\(type.scene)"
                qqSchemeURLString += "&callback_type=scheme&generalpastboard=1"
                qqSchemeURLString += "&callback_name=\(callbackName)"

                qqSchemeURLString += "&src_type=app&shareType=0&file_type="

                if let media = type.info.media {

                    switch media {

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

                    if let encodedTitle = type.info.title?.base64AndURLEncodedString {
                        qqSchemeURLString += "&title=\(encodedTitle)"
                    }

                    if let encodedDescription = type.info.description?.base64AndURLEncodedString {
                        qqSchemeURLString += "&objectlocation=pasteboard&description=\(encodedDescription)"
                    }

                } else { // Share Text

                    qqSchemeURLString += "text&file_data="

                    if let encodedDescription = type.info.description?.base64AndURLEncodedString {
                        qqSchemeURLString += "\(encodedDescription)"
                    }
                }

                if !openURL(URLString: qqSchemeURLString) {
                    finish(false)
                }
            }

        case .Weibo(let type):
            for case let .Weibo(appID, _, _) in sharedMonkeyKing.accountSet {

                guard !canOpenURL(NSURL(string: "weibosdk://request")) else {

                    // App Share

                    var messageInfo: [String: AnyObject] = ["__class": "WBMessageObject"]
                    let info = type.info

                    if let description = info.description {
                        messageInfo["text"] = description
                    }

                    if let media = info.media {
                        switch media {
                        case .URL(let URL):

                            var mediaObject: [String: AnyObject] = [
                                "__class": "WBWebpageObject",
                                "objectID": "identifier1"
                            ]

                            if let title = info.title {
                                mediaObject["title"] = title
                            }

                            if let thumbnailImage = info.thumbnail,
                                let thumbnailData = UIImageJPEGRepresentation(thumbnailImage, 0.7) {
                                    mediaObject["thumbnailData"] = thumbnailData
                            }

                            mediaObject["webpageUrl"] = URL.absoluteString

                            messageInfo["mediaObject"] = mediaObject

                        case .Image(let image):

                            if let imageData = UIImageJPEGRepresentation(image, 1.0) {
                                messageInfo["imageObject"] = ["imageData": imageData]
                            }
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

                    if !openURL(URLString: "weibosdk://request?id=\(uuIDString)&sdkversion=003013000") {
                        finish(false)
                    }

                    return
                }

                // Web Share

                let info = type.info
                var parameters = [String: AnyObject]()

                guard let accessToken = type.accessToken else {
                    print("When Weibo did not install, accessToken must need")
                    finish(false)
                    return
                }

                parameters["access_token"] = accessToken

                var statusText = ""

                if let title = info.title {
                    statusText += title
                }

                if let description = info.description {
                    statusText += description
                }

                var mediaType = Media.URL(NSURL())

                if let media = info.media {

                    switch media {

                    case .URL(let URL):

                        statusText += URL.absoluteString

                        mediaType = Media.URL(URL)

                    case .Image(let image):

                        guard let imageData = UIImageJPEGRepresentation(image, 0.7) else {
                            finish(false)
                            return
                        }

                        parameters["pic"] = imageData
                        mediaType = Media.Image(image)
                    }

                }

                parameters["status"] = statusText

                switch mediaType {

                case .URL(_):

                    let URLString = "https://api.weibo.com/2/statuses/update.json"
                    sendRequest(URLString, method: .POST, parameters: parameters) { (responseData, HTTPResponse, error) -> Void in
                        if let JSON = responseData, let _ = JSON["idstr"] as? String {
                            finish(true)
                        } else {
                            print("responseData \(responseData) HTTPResponse \(HTTPResponse)")
                            finish(false)
                        }
                    }
                    
                case .Image(_):

                    let URLString = "https://upload.api.weibo.com/2/statuses/upload.json"
                    guard let URL = NSURL(string: URLString) else {
                        finish(false)
                        return
                    }

                    SimpleNetworking.sharedInstance.upload(URL, parameters: parameters) { (responseData, HTTPResponse, error) -> Void in
                        if let JSON = responseData, let _ = JSON["idstr"] as? String {
                            finish(true)
                        } else {
                            print("responseData \(responseData) HTTPResponse \(HTTPResponse)")
                            finish(false)
                        }
                    }

                }

            }
        }
    }
}

// MARK: OAuth

extension MonkeyKing {

    public typealias SerializeResponse = (NSDictionary?, NSURLResponse?, NSError?) -> Void

    public class func OAuth(account: Account, scope: String? = nil, completionHandler: SerializeResponse) {

        guard account.isAppInstalled || account.isWeiboAccount else {
            let error = NSError(domain: "App is not installed", code: -2, userInfo: nil)
            completionHandler(nil, nil, error)
            return
        }

        sharedMonkeyKing.oauthCompletionHandler = completionHandler

        switch account {

            case .WeChat(let appID, _):

                let scope = scope ?? "snsapi_userinfo"
                openURL(URLString: "weixin://app/\(appID)/auth/?scope=\(scope)&state=Weixinauth")

            case .QQ(let appID):

                let scope = scope ?? ""
                let appName = NSBundle.mainBundle().displayName ?? "nixApp"
                let dic = ["app_id": appID,
                    "app_name": appName,
                    "client_id": appID,
                    "response_type": "token",
                    "scope": scope,
                    "sdkp": "i",
                    "sdkv": "2.9",
                    "status_machine": UIDevice.currentDevice().model,
                    "status_os": UIDevice.currentDevice().systemVersion,
                    "status_version": UIDevice.currentDevice().systemVersion]

                let data = NSKeyedArchiver.archivedDataWithRootObject(dic)
                UIPasteboard.generalPasteboard().setData(data, forPasteboardType: "com.tencent.tencent\(appID)")

                openURL(URLString: "mqqOpensdkSSoLogin://SSoLogin/tencent\(appID)/com.tencent.tencent\(appID)?generalpastboard=1")

            case .Weibo(let appID, _, let redirectURL):

                guard !canOpenURL(NSURL(string: "weibosdk://request")) else {
                    let scope = scope ?? "all"
                    let uuIDString = CFUUIDCreateString(nil, CFUUIDCreate(nil))
                    let authData = [
                        ["transferObject": NSKeyedArchiver.archivedDataWithRootObject(["__class": "WBAuthorizeRequest", "redirectURI": redirectURL, "requestID":uuIDString, "scope": scope])
                        ],
                        ["userInfo": NSKeyedArchiver.archivedDataWithRootObject(["mykey": "as you like", "SSO_From": "SendMessageToWeiboViewController"])],
                        ["app": NSKeyedArchiver.archivedDataWithRootObject(["appKey": appID, "bundleID": NSBundle.mainBundle().bundleID ?? "", "name": NSBundle.mainBundle().displayName ?? ""])]
                    ]

                    UIPasteboard.generalPasteboard().items = authData
                    openURL(URLString: "weibosdk://request?id=\(uuIDString)&sdkversion=003013000")
                    return
                }

                // Web OAuth
                let accessTokenAPI = "https://open.weibo.cn/oauth2/authorize?client_id=\(appID)&response_type=code&redirect_uri=\(redirectURL)&scope=\(scope)"

                guard let URL = NSURL(string: accessTokenAPI) else {
                    return
                }

                let webView = WKWebView()
                webView.frame = UIScreen.mainScreen().bounds
                webView.frame.origin.y = UIScreen.mainScreen().bounds.height

                webView.loadRequest(NSURLRequest(URL: URL))
                webView.navigationDelegate = sharedMonkeyKing
                webView.backgroundColor = UIColor(red: 247/255, green: 247/255, blue: 247/255, alpha: 1.0)
                webView.scrollView.frame.origin.y = 20
                webView.scrollView.backgroundColor = webView.backgroundColor

                let activityIndicatorView = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
                activityIndicatorView.center = CGPoint(x: CGRectGetMidX(webView.bounds), y: CGRectGetMidY(webView.bounds)+30)
                activityIndicatorView.activityIndicatorViewStyle = .Gray

                webView.scrollView.addSubview(activityIndicatorView)
                activityIndicatorView.startAnimating()

                UIApplication.sharedApplication().keyWindow?.addSubview(webView)
                UIView.animateWithDuration(0.32, delay: 0.0, options: .CurveEaseOut, animations: {
                    webView.frame.origin.y = 0
                }, completion: nil)

        }
    }


    private class func fetchWeChatUserInfoByCode(code code: String, completionHandler: SerializeResponse) {

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

        // OAuth
        sendRequest(accessTokenAPI, method: .GET) { (OAuthJSON, response, error) -> Void in

            var userInfoDictionary: NSDictionary?

            guard let accessToken = OAuthJSON?["access_token"] as? String,
                let openID = OAuthJSON?["openid"] as? String,
                let refreshToken = OAuthJSON?["refresh_token"] as? String,
                let expiresIn = OAuthJSON?["expires_in"] as? Int else {
                    completionHandler(userInfoDictionary, response, error)
                    return
            }

            let userInfoAPI = "https://api.weixin.qq.com/sns/userinfo?access_token=\(accessToken)&openid=\(openID)"

            // fetch UserInfo
            sendRequest(userInfoAPI, method: .GET) { (userInfoJSON, response, error) -> Void in

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

}


// MARK: WKNavigationDelegate

extension MonkeyKing: WKNavigationDelegate {

    public func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        for subview in webView.scrollView.subviews {
            if let activityIndicatorView = subview as? UIActivityIndicatorView {
                activityIndicatorView.stopAnimating()
            }
        }

        let HTML = "var button = document.createElement('a'); button.setAttribute('href', 'about:blank'); button.innerHTML = '关闭'; button.setAttribute('style', 'width: calc(100% - 40px); background-color: gray;display: inline-block;height: 40px;line-height: 40px;text-align: center;color: #777777;text-decoration: none;border-radius: 3px;background: linear-gradient(180deg, white, #f1f1f1);border: 1px solid #CACACA;box-shadow: 0 2px 3px #DEDEDE, inset 0 0 0 1px white;text-shadow: 0 2px 0 white;position: absolute;bottom: 0;margin: 20px 20px 40px 20px;font-size: 18px;'); document.body.appendChild(button);  document.querySelector('aside.logins').style.display = 'none';"

        webView.evaluateJavaScript(HTML, completionHandler: nil)
    }

    public func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {
        UIView.animateWithDuration(0.3, delay: 0.0, options: .CurveEaseOut, animations: {
            webView.frame.origin.y = UIScreen.mainScreen().bounds.height
        }, completion: {_ in
            webView.removeFromSuperview()
            self.oauthCompletionHandler?(nil, nil, error)
        })
    }

    public func webView(webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError) {
        UIView.animateWithDuration(0.3, delay: 0.0, options: .CurveEaseOut, animations: {
            webView.frame.origin.y = UIScreen.mainScreen().bounds.height
        }, completion: {_ in
            webView.removeFromSuperview()
            self.oauthCompletionHandler?(nil, nil, error)
        })
    }

    public func webView(webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {

        guard let URL = webView.URL else {
            webView.stopLoading()
            return
        }

        if URL.absoluteString.rangeOfString("about:blank") != nil {

            let error = NSError(domain: "User Cancelled", code: -1, userInfo: nil)
            webView.stopLoading()

            UIView.animateWithDuration(0.3, delay: 0.0, options: .CurveEaseOut, animations: {
                webView.frame.origin.y = UIScreen.mainScreen().bounds.height
            }, completion: {_ in
                webView.removeFromSuperview()
                self.oauthCompletionHandler?(nil, nil, error)
            })
        }

    }

    public func webView(webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {

        guard let URL = webView.URL else {
            return
        }

        for case let .Weibo(appID, appKey, redirectURL) in accountSet {
            if URL.absoluteString.lowercaseString.hasPrefix(redirectURL) {

                webView.stopLoading()

                guard let code = URL.queryInfo["code"] else {
                    return
                }

                var accessTokenAPI = "https://api.weibo.com/oauth2/access_token?"
                accessTokenAPI += "client_id=" + appID
                accessTokenAPI += "&client_secret=" + appKey
                accessTokenAPI += "&grant_type=authorization_code&"
                accessTokenAPI += "redirect_uri=" + redirectURL
                accessTokenAPI += "&code=" + code

                sendRequest(accessTokenAPI, method: .POST) { [weak self] (JSON, response, error) -> Void in
                    self?.oauthCompletionHandler?(JSON, response, error)
                }

                UIView.animateWithDuration(0.3, delay: 0.0, options: .CurveEaseOut, animations: {
                    webView.frame.origin.y = UIScreen.mainScreen().bounds.height
                }, completion: {_ in
                    webView.removeFromSuperview()
                })
            }
        }
        
    }
}

// MARK: Private Methods

private func sendRequest(URLString: String, method: SimpleNetworking.Method, parameters: [String: AnyObject]? = nil, completionHandler: MonkeyKing.SerializeResponse) {
    guard let URL = NSURL(string: URLString) else {
        print("URL init Error: URLString")
        return
    }
    SimpleNetworking.sharedInstance.request(URL, method: method, parameters: parameters, completionHandler: completionHandler)
}

private func openURL(URLString URLString: String) -> Bool {
    guard let URL = NSURL(string: URLString) else {
        return false
    }
    return UIApplication.sharedApplication().openURL(URL)
}

private func canOpenURL(URL: NSURL?) -> Bool {
    guard let URL = URL else {
        return false
    }
    return UIApplication.sharedApplication().canOpenURL(URL)
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

