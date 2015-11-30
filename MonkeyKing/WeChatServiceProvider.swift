//
//  WeChatServiceProvider.swift
//  China
//
//  Created by Shannon Wu on 11/29/15.
//  Copyright © 2015 nixWork. All rights reserved.
//

import Foundation

public class WeChatServiceProvier: ShareServiceProvider {
    /// 分享的目的地
    public enum Destination: Int {
        /// 分享到会话
        case Session = 0
        /// 分享到朋友圈
        case Timeline = 1
    }

    public static var appInstalled: Bool {
        return URLHandler.canOpenURL(NSURL(string: "weixin://"))
    }

    public var appID: String
    public var appKey: String?
    public var destination: Destination?
    public var shareCompletionHandler: ShareCompletionHandler?
    public var oauthCompletionHandler: NetworkResponseHandler?

    public init(appID: String, appKey: String?, destination: Destination? = nil) {
        self.appID = appID
        self.appKey = appKey
        self.destination = destination
    }

    public func canShareContent(content: Content) -> Bool {
        return true
    }

    public func shareContent(content: Content, completionHandler: ShareCompletionHandler? = nil) throws {
        guard WeChatServiceProvier.appInstalled else {
            throw ShareError.AppNotInstalled
        }

        guard canShareContent(content) else {
            throw ShareError.ContentNotLegal
        }

        self.shareCompletionHandler = completionHandler

        var weChatMessageInfo: [String:AnyObject]
        if let destination = destination {
            weChatMessageInfo = ["result": "1", "returnFromApp": "0", "scene": destination.rawValue, "sdkver": "1.5", "command": "1010", ]
        }
        else {
            throw ShareError.DestinationNotPointed
        }

        if let title = content.title {
            weChatMessageInfo["title"] = title
        }

        if let description = content.description {
            weChatMessageInfo["description"] = description
        }

        if let thumbnailImage = content.thumbnail, let thumbnailData = UIImageJPEGRepresentation(thumbnailImage, 0.5) {
            weChatMessageInfo["thumbData"] = thumbnailData
        }

        if let media = content.media {
            switch media {
                case .URL(let URL):
                    weChatMessageInfo["objectType"] = "5"
                    weChatMessageInfo["mediaUrl"] = URL.absoluteString

                case .Image(let image):
                    weChatMessageInfo["objectType"] = "2"

                    if let fileImageData = UIImageJPEGRepresentation(image, 1) {
                        weChatMessageInfo["fileData"] = fileImageData
                    }

                case .Audio(let audioURL, let linkURL):
                    weChatMessageInfo["objectType"] = "3"

                    if let linkURL = linkURL {
                        weChatMessageInfo["mediaUrl"] = linkURL.absoluteString
                    }

                    weChatMessageInfo["mediaDataUrl"] = audioURL.absoluteString

                case .Video(let URL):
                    weChatMessageInfo["objectType"] = "4"
                    weChatMessageInfo["mediaUrl"] = URL.absoluteString
            }

        }
        else {
            weChatMessageInfo["command"] = "1020"
        }

        let weChatMessage = [appID: weChatMessageInfo]

        guard let data = try? NSPropertyListSerialization.dataWithPropertyList(weChatMessage, format: .BinaryFormat_v1_0, options: 0) else {
            throw ShareError.FormattingError
        }

        UIPasteboard.generalPasteboard().setData(data, forPasteboardType: "content")

        let weChatSchemeURLString = "weixin://app/\(appID)/sendreq/?"

        if !URLHandler.openURL(URLString: weChatSchemeURLString) {
            throw ShareError.FormattingError
        }
    }

    public func OAuth(completionHandler: NetworkResponseHandler) throws {
        oauthCompletionHandler = completionHandler

        guard WeChatServiceProvier.appInstalled else {
            throw ShareError.AppNotInstalled
        }

        let scope = "snsapi_userinfo"
        URLHandler.openURL(URLString: "weixin://app/\(appID)/auth/?scope=\(scope)&state=Weixinauth")
    }

    func fetchWeChatOAuthInfoByCode(code code: String, completionHandler: NetworkResponseHandler) {
        guard let key = appKey else {
            completionHandler(["code": code], nil, nil)
            return
        }

        var accessTokenAPI = "https://api.weixin.qq.com/sns/oauth2/access_token?"
        accessTokenAPI += "appid=" + appID
        accessTokenAPI += "&secret=" + key
        accessTokenAPI += "&code=" + code + "&grant_type=authorization_code"

        SimpleNetworking.sharedInstance.request(accessTokenAPI, method: .GET) {
            (OAuthJSON, response, error) -> Void in
            completionHandler(OAuthJSON, response, error)
        }
    }

    public func handleOpenURL(URL: NSURL) -> Bool {
        if URL.scheme.hasPrefix("wx") {
            // WeChat OAuth
            if URL.absoluteString.containsString("&state=Weixinauth") {
                let components = NSURLComponents(URL: URL, resolvingAgainstBaseURL: false)

                guard let items = components?.queryItems else {
                    return false
                }

                var infos = [String: AnyObject]()
                items.forEach {
                    infos[$0.name] = $0.value
                }

                guard let code = infos["code"] as? String else {
                    return false
                }

                // Login Succcess
                fetchWeChatOAuthInfoByCode(code: code) {
                    (info, response, error) -> Void in
                    self.oauthCompletionHandler?(info, response, error)
                }
                return true
            }

            // WeChat Share
            guard let data = UIPasteboard.generalPasteboard().dataForPasteboardType("content") else {
                return false
            }

            if let dic = try? NSPropertyListSerialization.propertyListWithData(data, options: .Immutable, format: nil) {
                if let dic = dic[appID] as? NSDictionary,
                       result = dic["result"]?.integerValue {
                        let succeed = (result == 0)
                        shareCompletionHandler?(succeed: succeed)
                        return succeed
                }
            }
        }

        // Other
        return false
    }
}
