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
            case Session
            case Timeline

            var scene: String {
                switch self {
                case .Session:
                    return "0"
                case .Timeline:
                    return "1"
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

                var info: [String: String] = [
                    "result": "1",
                    "returnFromApp": "0",
                    "scene": type.scene,
                    "sdkver": "1.5",
                    "command": "1010",
                ]

                switch type {
                case .Session:

                    info["title"] = "Hello"
                    info["mediaUrl"] = "http://baidu.com"
                    info["objectType"] = "5"

                case .Timeline:
                    break
                }

                let dic = [appID: info]

                guard let data = try? NSPropertyListSerialization.dataWithPropertyList(dic, format: NSPropertyListFormat.BinaryFormat_v1_0, options: NSPropertyListWriteOptions(0)) else {
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

