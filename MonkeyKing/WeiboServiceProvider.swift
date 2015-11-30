//
//  WeiboServiceProvider.swift
//  China
//
//  Created by Shannon Wu on 11/29/15.
//  Copyright © 2015 nixWork. All rights reserved.
//

import Foundation

public class WeiboServiceProvier: ShareServiceProvider {
    public static var appInstalled: Bool {
        return URLHandler.canOpenURL(NSURL(string: "weibosdk://request"))
    }

    lazy var webviewProvider: SimpleWebView = {
        let webViewProvider = SimpleWebView()
        webViewProvider.shareServiceProvider = self
        return webViewProvider
    }()

    public var appID: String
    public var appKey: String
    public var accessToken: String?
    public var redirectURL: String
    var shareCompletionHandler: ShareCompletionHandler?
    public var oauthCompletionHandler: NetworkResponseHandler?

    public init(appID: String, appKey: String, redirectURL: String, accessToken: String? = nil) {
        self.appID = appID
        self.appKey = appKey
        self.redirectURL = redirectURL
        self.accessToken = accessToken
    }

    public func canShareContent(content: Content) -> Bool {
        if content.description == nil && content.media == nil {
            return false
        }
        return true
    }

    public func shareContent(content: Content, completionHandler: ShareCompletionHandler? = nil) throws {
        guard canShareContent(content) else {
            throw ShareError.ContentNotLegal
        }

        self.shareCompletionHandler = completionHandler

        guard !URLHandler.canOpenURL(NSURL(string: "weibosdk://request")) else {
            var messageInfo: [String:AnyObject] = ["__class": "WBMessageObject"]

            if let description = content.description {
                messageInfo["text"] = description
            }

            if let media = content.media {
                switch media {
                    case .URL(let URL):
                        var mediaObject: [String:AnyObject] = ["__class": "WBWebpageObject", "objectID": "identifier1"]

                        if let title = content.title {
                            mediaObject["title"] = title
                        }

                        if let thumbnailImage = content.thumbnail, let thumbnailData = UIImageJPEGRepresentation(thumbnailImage, 0.7) {
                            mediaObject["thumbnailData"] = thumbnailData
                        }

                        mediaObject["webpageUrl"] = URL.absoluteString

                        messageInfo["mediaObject"] = mediaObject

                    case .Image(let image):
                        if let imageData = UIImageJPEGRepresentation(image, 1.0) {
                            messageInfo["imageObject"] = ["imageData": imageData]
                        }

                    case .Audio:
                        throw ShareError.ContentNotLegal

                    case .Video:
                        throw ShareError.ContentNotLegal
                }
            }

            let uuIDString = CFUUIDCreateString(nil, CFUUIDCreate(nil))
            let dict = ["__class": "WBSendMessageToWeiboRequest", "message": messageInfo, "requestID": uuIDString]

            let messageData: [AnyObject] = [["transferObject": NSKeyedArchiver.archivedDataWithRootObject(dict)], ["userInfo": NSKeyedArchiver.archivedDataWithRootObject([])], ["app": NSKeyedArchiver.archivedDataWithRootObject(["appKey": appID, "bundleID": NSBundle.mainBundle().monkeyking_bundleID ?? ""])]]

            UIPasteboard.generalPasteboard().items = messageData

            if !URLHandler.openURL(URLString: "weibosdk://request?id=\(uuIDString)&sdkversion=003013000") {
                throw ShareError.FormattingError
            }

            return
        }

        // Web Share

        var parameters = [String: AnyObject]()

        guard let accessToken = accessToken else {
            throw ShareError.InternalError
        }

        parameters["access_token"] = accessToken

        var statusText = ""

        if let title = content.title {
            statusText += title
        }

        if let description = content.description {
            statusText += description
        }

        var mediaType = Content.Media.URL(NSURL())

        if let media = content.media {

            switch media {

                case .URL(let URL):

                    statusText += URL.absoluteString

                    mediaType = Content.Media.URL(URL)

                case .Image(let image):

                    guard let imageData = UIImageJPEGRepresentation(image, 0.7) else {
                        ShareError.FormattingError
                        return
                    }

                    parameters["pic"] = imageData
                    mediaType = Content.Media.Image(image)

                case .Audio:
                    ShareError.ContentNotLegal

                case .Video:
                    ShareError.ContentNotLegal
            }
        }

        parameters["status"] = statusText

        switch mediaType {

            case .URL(_ ):
                let URLString = "https://api.weibo.com/2/statuses/update.json"
                SimpleNetworking.sharedInstance.request(URLString, method: .POST, parameters: parameters) {
                    (responseData, HTTPResponse, error) -> Void in if let JSON = responseData, let _ = JSON["idstr"] as? String {
                        completionHandler?(succeed: true)
                    }
                    else {
                        completionHandler?(succeed: false)
                    }
                }

            case .Image(_ ):
                let URLString = "https://upload.api.weibo.com/2/statuses/upload.json"
                guard let URL = NSURL(string: URLString) else {
                    ShareError.FormattingError
                    return
                }

                SimpleNetworking.sharedInstance.upload(URL, parameters: parameters) {
                    (responseData, HTTPResponse, error) -> Void in if let JSON = responseData, let _ = JSON["idstr"] as? String {
                        completionHandler?(succeed: true)
                    }
                    else {
                        completionHandler?(succeed: false)
                    }
                }
            
            case .Audio:
                ShareError.ContentNotLegal

            case .Video:
                ShareError.ContentNotLegal
        }
    }

    public func OAuth(completionHandler: NetworkResponseHandler) throws {
        let scope = "all"

        self.oauthCompletionHandler = completionHandler

        guard !WeiboServiceProvier.appInstalled else {
            let uuIDString = CFUUIDCreateString(nil, CFUUIDCreate(nil))
            let authData = [["transferObject": NSKeyedArchiver.archivedDataWithRootObject(["__class": "WBAuthorizeRequest", "redirectURI": redirectURL, "requestID": uuIDString, "scope": scope])], ["userInfo": NSKeyedArchiver.archivedDataWithRootObject(["mykey": "as you like", "SSO_From": "SendMessageToWeiboViewController"])], ["app": NSKeyedArchiver.archivedDataWithRootObject(["appKey": appID, "bundleID": NSBundle.mainBundle().monkeyking_bundleID ?? "", "name": NSBundle.mainBundle().monkeyking_displayName ?? ""])]]

            UIPasteboard.generalPasteboard().items = authData
            URLHandler.openURL(URLString: "weibosdk://request?id=\(uuIDString)&sdkversion=003013000")
            return
        }

        let accessTokenAPI = "https://open.weibo.cn/oauth2/authorize?client_id=\(appID)&response_type=code&redirect_uri=\(redirectURL)&scope=\(scope)"
        webviewProvider.addWebViewByURLString(accessTokenAPI)
    }

    public func handleOpenURL(URL: NSURL) -> Bool {
        if URL.scheme.hasPrefix("wb") {
            guard let items = UIPasteboard.generalPasteboard().items as? [[String:AnyObject]] else {
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

            guard let responseData = results["transferObject"] as? [String:AnyObject], let type = responseData["__class"] as? String else {
                return false
            }

            guard let statusCode = responseData["statusCode"] as? Int else {
                return false
            }

            switch type {

                case "WBAuthorizeResponse":
                    var userInfoDictionary: NSDictionary?
                    var error: NSError?

                    defer {
                        oauthCompletionHandler?(responseData, nil, error)
                    }

                    userInfoDictionary = responseData

                    if statusCode != 0 {
                        error = NSError(domain: "OAuth Error", code: -1, userInfo: nil)
                        return false
                    }
                    return true

                case "WBSendMessageToWeiboResponse":
                    let succeed = (statusCode == 0)
                    shareCompletionHandler?(succeed: succeed)

                    return succeed
                default:
                    break
            }

        }

        // Other
        return false
    }

}