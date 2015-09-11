//
//  MonkeyKing.swift
//  MonkeyKing
//
//  Created by NIX on 15/9/11.
//  Copyright © 2015年 nixWork. All rights reserved.
//

import UIKit

public class MonkeyKing {

    static let sharedMonkeyKing = MonkeyKing()

    public enum Account {
        case WeChat(appID: String)
    }

    var accounts = [Account]()

    public class func registerAccount(account: Account)  {
        sharedMonkeyKing.accounts.append(account)
    }

    public class func handleOpenURL(URL: NSURL) -> Bool {
        return false
    }

    public enum Message {

        public enum WeChatType {

            public struct Info {
                let title: String?
                let description: String?
                let thumbnail: UIImage?

                public enum Media {
                    case URL(NSURL)
                    case Image(UIImage)
                }
                let media: Media

                public init(title: String?, description: String?, thumbnail: UIImage?, media: Media) {
                    self.title = title
                    self.description = description
                    self.thumbnail = thumbnail
                    self.media = media
                }
            }

            case Session(Info)
            case Timeline(Info)

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
        case WeChat(WeChatType)
    }

    public typealias Finish = Bool -> Void

    public class func shareMessage(message: Message, finish: Finish) {

        switch message {

        case .WeChat(let type):

            for case let .WeChat(appID) in sharedMonkeyKing.accounts {

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
                
                UIApplication.sharedApplication().openURL(URL)
            }
        }
    }
}

