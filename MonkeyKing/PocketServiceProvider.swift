//
//  PocketServiceProvider.swift
//  China
//
//  Created by Shannon Wu on 11/30/15.
//  Copyright © 2015 nixWork. All rights reserved.
//

import Foundation

public class PocketServiceProvider: ShareServiceProvider {

    public var appID: String
    var accessToken: String?
    var requestToken: String?

    lazy var webviewProvider: SimpleWebView = {
        let webViewProvider = SimpleWebView()
        webViewProvider.shareServiceProvider = self
        return webViewProvider
    }()

    var shareCompletionHandler: ShareCompletionHandler?
    public var oauthCompletionHandler: NetworkResponseHandler?

    public init(appID: String, accessToken: String?) {
        self.appID = appID
        self.accessToken = accessToken
    }

    public func canShareContent(content: Content) -> Bool {
        guard content.media != nil else {
            return false
        }
        
        switch content.media! {
            case .URL:
                return true
            
            default:
                return false
        }
    }

    public static var appInstalled: Bool {
        return URLHandler.canOpenURL(NSURL(string: "pocket-oauth-v1://"))
    }

    public func handleOpenURL(URL: NSURL) -> Bool {
        if URL.scheme.hasPrefix("pocketapp") {
            guard let accessTokenAPI = NSURL(string: "https://getpocket.com/v3/oauth/authorize") else {
                return true
            }

            guard let requestToken = requestToken else {
                return true
            }

            let parameters = ["consumer_key": self.appID, "code": requestToken]

            SimpleNetworking.sharedInstance.request(accessTokenAPI, method: .POST, parameters: parameters) {
                (dictionary, response, error) -> Void in self.oauthCompletionHandler?(dictionary, response, error)
            }
            return true
        }
        return false
    }

    public func OAuth(completionHandler: NetworkResponseHandler) throws {
        oauthCompletionHandler = completionHandler

        guard let startIndex = appID.rangeOfString("-")?.startIndex else {
            throw ShareError.InternalError
        }

        let prefix = appID.substringToIndex(startIndex)
        guard let requestAPI = NSURL(string: "https://getpocket.com/v3/oauth/request") else {
            throw ShareError.FormattingError
        }
        let redirectURLString = "pocketapp\(prefix):authorizationFinished"

        let parameters = ["consumer_key": appID, "redirect_uri": redirectURLString]

        SimpleNetworking.sharedInstance.request(requestAPI, method: .POST, parameters: parameters) {
            (dictionary, response, error) -> Void in

            guard let requestToken = dictionary?["code"] as? String else {
                return
            }

            self.requestToken = requestToken

            guard !PocketServiceProvider.appInstalled else {
                let requestTokenAPI = "pocket-oauth-v1:///authorize?request_token=\(requestToken)&redirect_uri=\(redirectURLString)"
                URLHandler.openURL(URLString: requestTokenAPI)
                return
            }

            let requestTokenAPI = "https://getpocket.com/auth/authorize?request_token=\(requestToken)&redirect_uri=\(redirectURLString)"
            dispatch_async(dispatch_get_main_queue()) {
                self.webviewProvider.addWebViewByURLString(requestTokenAPI, flagCode: requestToken)
            }
        }

    }

    public func shareContent(content: Content, completionHandler: ShareCompletionHandler? = nil) throws {
        guard canShareContent(content) else {
            throw ShareError.ContentNotLegal
        }

        guard let accessToken = accessToken else {
            throw ShareError.InternalError
        }

        guard let addAPI = NSURL(string: "https://getpocket.com/v3/add") else {
            throw ShareError.FormattingError
        }

        shareCompletionHandler = completionHandler

        var parameters = ["consumer_key": appID, "access_token": accessToken]

        let URLString: String
        guard let media = content.media else {
            throw ShareError.ContentNotLegal
        }
        switch media {
            case .URL(let url):
                URLString = url.absoluteString
            
            default:
                throw ShareError.ContentNotLegal
        }

        parameters["url"] = URLString

        if let title = content.title {
            parameters["title"] = title
        }

        SimpleNetworking.sharedInstance.request(addAPI, method: .POST, parameters: parameters) {
            (dict, response, error) -> Void in
            if error != nil {
                self.shareCompletionHandler?(succeed: false)
            }
            else {
                self.shareCompletionHandler?(succeed: true)
            }
        }
    }
}