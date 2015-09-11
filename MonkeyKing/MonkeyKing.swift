//
//  MonkeyKing.swift
//  MonkeyKing
//
//  Created by NIX on 15/9/11.
//  Copyright © 2015年 nixWork. All rights reserved.
//

import UIKit

public class MonkeyKing {

    static let monkeyKing = MonkeyKing()

    public enum Account {
        case WeChat(appID: String)
    }

    var accounts = [Account]()

    public class func registerAccount(account: Account)  {
        monkeyKing.accounts.append(account)
    }

    public class func handleOpenURL(URL: NSURL) -> Bool {
        return false
    }

    public enum Message {

        public enum WeChatType {
            case Session
            case Timeline
        }
        case WeChat(WeChatType)
    }

    public typealias Finish = Bool -> Void

    public class func shareMessage(message: Message, finish: Finish) {

        let appID = "wxd930ea5d5a258f4f"

        let dic = [
            appID: [
                "result": "1",
                "returnFromApp": "0",
                "scene": "0",
                "sdkver": "1.5",
                "command": "1010",

                "title": "Hello",
                "mediaUrl": "http://baidu.com",
                "objectType": "5",
            ]
        ]

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

