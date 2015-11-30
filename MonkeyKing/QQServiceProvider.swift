//
//  QQServiceProvider.swift
//  China
//
//  Created by Shannon Wu on 11/29/15.
//  Copyright © 2015 nixWork. All rights reserved.
//

import Foundation

public class QQServiceProvider: ShareServiceProvider {
    /// 分享的目的地
    public enum Destination: Int {
        /// 朋友圈
        case Friends = 0
        /// QQ 空间
        case QZone = 1
    }

    /// 获取用户资料的范围
    public enum Scope: String {
        /// 获取用户基本资料
        case BasicInfo = "get_info"
        /// 批量获取用户基本资料
        case MultiInfo = "get_multi_info"
    }

    public static var appInstalled: Bool {
        return URLHandler.canOpenURL(NSURL(string: "mqqapi://"))
    }

    lazy var webviewProvider: SimpleWebView = {
        let webViewProvider = SimpleWebView()
        webViewProvider.shareServiceProvider = self
        return webViewProvider
    }()

    public var appID: String
    public var destination: Destination?
    public var scope: Scope = .BasicInfo
    public var shareCompletionHandler: ShareCompletionHandler?
    public var oauthCompletionHandler: NetworkResponseHandler?

    public init(appID: String, destination: Destination? = nil, scope: Scope = .BasicInfo) {
        self.appID = appID
        self.destination = destination
        self.scope = scope
    }

    var callBackName: String {
        var hexString = String(format: "%02llx", (appID as NSString).longLongValue)
        while hexString.characters.count < 8 {
            hexString = "0" + hexString
        }

        return "QQ" + hexString
    }

    public func canShareContent(content: Content) -> Bool {
        return true
    }

    public func shareContent(content: Content, completionHandler: ShareCompletionHandler? = nil) throws {
        guard canShareContent(content) else {
            throw ShareError.ContentNotLegal
        }

        guard QQServiceProvider.appInstalled else {
            throw ShareError.AppNotInstalled
        }

        self.shareCompletionHandler = completionHandler

        var qqSchemeURLString = "mqqapi://share/to_fri?"

        if let encodedAppDisplayName = NSBundle.mainBundle().monkeyking_displayName?.monkeyking_base64EncodedString {
            qqSchemeURLString += "thirdAppDisplayName=" + encodedAppDisplayName
        }
        else {
            throw ShareError.FormattingError
        }

        if let destination = destination {
            qqSchemeURLString += "&version=1&cflag=\(destination.rawValue)"
        }
        else {
            throw ShareError.DestinationNotPointed
        }
        qqSchemeURLString += "&callback_type=scheme&generalpastboard=1"
        qqSchemeURLString += "&callback_name=\(callBackName)"
        qqSchemeURLString += "&src_type=app&shareType=0&file_type="

        if let media = content.media {

            func handleNewsWithURL(URL: NSURL, mediaType: String?) throws {
                if let thumbnail = content.thumbnail, thumbnailData = UIImageJPEGRepresentation(thumbnail, 1) {
                    let dic = ["previewimagedata": thumbnailData]
                    let data = NSKeyedArchiver.archivedDataWithRootObject(dic)
                    UIPasteboard.generalPasteboard().setData(data, forPasteboardType: "com.tencent.mqq.api.apiLargeData")
                }

                qqSchemeURLString += mediaType ?? "news"

                guard let encodedURLString = URL.absoluteString.monkeyking_base64AndURLEncodedString else {
                    throw ShareError.FormattingError
                }

                qqSchemeURLString += "&url=\(encodedURLString)"
            }

            switch media {
                case .URL(let URL):
                    do {
                        try handleNewsWithURL(URL, mediaType: "news")
                    }
                    catch let error {
                        throw error
                    }

                case .Image(let image):
                    guard let imageData = UIImageJPEGRepresentation(image, 1) else {
                        throw ShareError.FormattingError
                    }

                    var dic = ["file_data": imageData, ]
                    if let thumbnail = content.thumbnail, thumbnailData = UIImageJPEGRepresentation(thumbnail, 1) {
                        dic["previewimagedata"] = thumbnailData
                    }

                    let data = NSKeyedArchiver.archivedDataWithRootObject(dic)

                    UIPasteboard.generalPasteboard().setData(data, forPasteboardType: "com.tencent.mqq.api.apiLargeData")

                    qqSchemeURLString += "img"

                case .Audio(let audioURL, _ ):
                    do {
                        try handleNewsWithURL(audioURL, mediaType: "audio")
                    }
                    catch let error {
                        throw error
                    }
                
                case .Video(let URL):
                    do {
                        try handleNewsWithURL(URL, mediaType: nil)
                    }
                    catch let error {
                        throw error
                    }
            }

            if let encodedTitle = content.title?.monkeyking_base64AndURLEncodedString {
                qqSchemeURLString += "&title=\(encodedTitle)"
            }

            if let encodedDescription = content.description?.monkeyking_base64AndURLEncodedString {
                qqSchemeURLString += "&objectlocation=pasteboard&description=\(encodedDescription)"
            }

        }
        else {
            qqSchemeURLString += "text&file_data="

            if let encodedDescription = content.description?.monkeyking_base64AndURLEncodedString {
                qqSchemeURLString += "\(encodedDescription)"
            }
        }

        if !URLHandler.openURL(URLString: qqSchemeURLString) {
            throw ShareError.FormattingError
        }
    }

    public func OAuth(completionHandler: NetworkResponseHandler) throws {
        oauthCompletionHandler = completionHandler

        let scope = self.scope.rawValue ?? ""
        guard !QQServiceProvider.appInstalled else {
            guard let appName = NSBundle.mainBundle().monkeyking_displayName else {
                throw ShareError.FormattingError
            }
            let dic = ["app_id": appID, "app_name": appName, "client_id": appID, "response_type": "token", "scope": scope, "sdkp": "i", "sdkv": "2.9", "status_machine": UIDevice.currentDevice().model, "status_os": UIDevice.currentDevice().systemVersion, "status_version": UIDevice.currentDevice().systemVersion]

            let data = NSKeyedArchiver.archivedDataWithRootObject(dic)
            UIPasteboard.generalPasteboard().setData(data, forPasteboardType: "com.tencent.tencent\(appID)")

            URLHandler.openURL(URLString: "mqqOpensdkSSoLogin://SSoLogin/tencent\(appID)/com.tencent.tencent\(appID)?generalpastboard=1")

            return
        }

        // Web OAuth
        let accessTokenAPI = "http://xui.ptlogin2.qq.com/cgi-bin/xlogin?appid=716027609&pt_3rd_aid=209656&style=35&s_url=http%3A%2F%2Fconnect.qq.com&refer_cgi=m_authorize&client_id=\(appID)&redirect_uri=auth%3A%2F%2Fwww.qq.com&response_type=token&scope=\(scope)"

        webviewProvider.addWebViewByURLString(accessTokenAPI)
    }

    public func handleOpenURL(URL: NSURL) -> Bool {
        // QQ Share
        if URL.scheme.hasPrefix("QQ") {
            guard let error = URL.monkeyking_queryInfo["error"] else {
                return false
            }
            let succeed = (error == "0")

            shareCompletionHandler?(succeed: succeed)
            return succeed
        }

        if URL.scheme.hasPrefix("tencent") {

            var userInfoDictionary: NSDictionary?
            var error: NSError?

            defer {
                oauthCompletionHandler?(userInfoDictionary, nil, error)
            }

            guard let data = UIPasteboard.generalPasteboard().dataForPasteboardType("com.tencent.tencent\(appID)"), let dic = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? NSDictionary else {
                error = NSError(domain: "OAuth Error", code: -1, userInfo: nil)
                return false
            }

            guard let result = dic["ret"]?.integerValue where result == 0 else {
                if let errorDomatin = dic["user_cancelled"] as? String where errorDomatin == "YES" {
                    error = NSError(domain: "User Cancelled", code: -2, userInfo: nil)
                }
                else {
                    error = NSError(domain: "OAuth Error", code: -1, userInfo: nil)
                }
                return false
            }

            userInfoDictionary = dic

            return true
        }

        // Other
        return false
    }
}
