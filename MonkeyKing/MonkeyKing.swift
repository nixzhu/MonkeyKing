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

        case WeChat(appID: String)
        case QQ(appID: String)

        func canOpenURL(URL: NSURL) -> Bool {
            return UIApplication.sharedApplication().canOpenURL(URL)
        }

        public var isAppInstalled: Bool {
            switch self {
            case .WeChat:
                return canOpenURL(NSURL(string: "weixin://")!)
            case .QQ:
                return canOpenURL(NSURL(string: "mqqapi://")!)
            }
        }

        public var appID: String {
            switch self {
            case .WeChat(let appID):
                return appID
            case .QQ(let appID):
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

            guard let data = UIPasteboard.generalPasteboard().dataForPasteboardType("content") else {
                return false
            }

            if let dic = try? NSPropertyListSerialization.propertyListWithData(data, options: .Immutable, format: nil) {

                for case let .WeChat(appID) in sharedMonkeyKing.accountSet {

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

        // TODO: handel others' URL

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
            }
        }
    }

    public typealias Finish = Bool -> Void

    var latestFinish: Finish?

    public class func shareMessage(message: Message, finish: Finish) {

        guard message.canBeDelivered else {
            finish(false)
            return
        }

        sharedMonkeyKing.latestFinish = finish

        switch message {

        case .WeChat(let type):

            for case let .WeChat(appID) in sharedMonkeyKing.accountSet {

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

                if let thumbnailImage = info.thumbnail {
                    weChatMessageInfo["thumbData"] = UIImageJPEGRepresentation(thumbnailImage, 0.7)!
                }

                switch info.media {

                case .URL(let URL):
                    weChatMessageInfo["objectType"] = "5"
                    weChatMessageInfo["mediaUrl"] = URL.absoluteString

                case .Image(let image):
                    weChatMessageInfo["objectType"] = "2"
                    weChatMessageInfo["fileData"] = UIImageJPEGRepresentation(image, 1)!
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

                var qqSchemeURLString = "mqqapi://share/to_fri?thirdAppDisplayName=\(NSBundle.mainBundle().displayName!.base64EncodedString!)"
                qqSchemeURLString+="&version=1&cflag=\(type.scene)"
                qqSchemeURLString+="&callback_type=scheme&generalpastboard=1"
                qqSchemeURLString+="&callback_name=\(callbackName)"
                qqSchemeURLString+="&src_type=app&shareType=0&file_type="

                switch type.info.media {
                case .URL(let URL):

                    let dic = ["previewimagedata": UIImageJPEGRepresentation(type.info.thumbnail!, 1)!]

                    let data = NSKeyedArchiver.archivedDataWithRootObject(dic)

                    UIPasteboard.generalPasteboard().setData(data, forPasteboardType: "com.tencent.mqq.api.apiLargeData")

                    qqSchemeURLString += "news"
                    qqSchemeURLString += "&title=\(type.info.title!.base64EncodedString!.urlEncodedString!)"
                    qqSchemeURLString += "&url=\(URL.absoluteString.base64EncodedString!.urlEncodedString!)"
                    qqSchemeURLString += "&objectlocation=pasteboard&description=\(type.info.description!.base64EncodedString!.urlEncodedString!)"

                case .Image(let image):

                    let imageData = UIImageJPEGRepresentation(image, 1)!
                    let dic = [
                        "file_data": imageData,
                        "previewimagedata": type.info.thumbnail ?? imageData
                    ]
                    let data = NSKeyedArchiver.archivedDataWithRootObject(dic)

                    UIPasteboard.generalPasteboard().setData(data, forPasteboardType: "com.tencent.mqq.api.apiLargeData")

                    qqSchemeURLString += "img"
                    qqSchemeURLString += "&title=\(type.info.title!.base64EncodedString!.urlEncodedString!)"
                    qqSchemeURLString += "&objectlocation=pasteboard&description=\(type.info.description!.base64EncodedString!.urlEncodedString!)"
                }

                print(qqSchemeURLString)
                
                guard let URL = NSURL(string: qqSchemeURLString) else {
                    return
                }
                
                if !UIApplication.sharedApplication().openURL(URL) {
                    finish(false)
                }
            }
        }
    }
}

extension NSBundle {

    var displayName: String? {
        return infoDictionary?["CFBundleIdentifier"] as? String
    }
}

extension String {

    var base64EncodedString: String? {
        return dataUsingEncoding(NSUTF8StringEncoding)?.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
    }

    var urlEncodedString: String? {
        return stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet())
    }
}

