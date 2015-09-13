//
//  ViewController.swift
//  China
//
//  Created by NIX on 15/9/11.
//  Copyright © 2015年 nixWork. All rights reserved.
//

import UIKit
import MonkeyKing

let weChatAppID = "wxd930ea5d5a258f4f"
let qqAppID = "1103194207"

class ViewController: UIViewController {

    @IBAction func shareURLToWeChatSession(sender: UIButton) {

        MonkeyKing.registerAccount(.WeChat(appID: weChatAppID))

        let message = MonkeyKing.Message.WeChat(.Session(info: (
            title: "Session",
            description: "Hello Session",
            thumbnail: UIImage(named: "rabbit"),
            media: .URL(NSURL(string: "http://www.apple.com/cn")!)
        )))

        MonkeyKing.shareMessage(message) { success in
            print("shareURLToWeChatSession success: \(success)")
        }
    }

    @IBAction func shareImageToWeChatTimeline(sender: UIButton) {

        MonkeyKing.registerAccount(.WeChat(appID: weChatAppID))

        let message = MonkeyKing.Message.WeChat(.Timeline(info: (
            title: "Timeline",
            description: "Hello Timeline",
            thumbnail: nil,
            media: .Image(UIImage(named: "rabbit")!)
        )))

        MonkeyKing.shareMessage(message) { success in
            print("shareImageToWeChatTimeline success: \(success)")
        }
    }

    @IBAction func shareURLToQQFriends(sender: UIButton) {

        MonkeyKing.registerAccount(.QQ(appID: qqAppID))

        let message = MonkeyKing.Message.QQ(.Friends(info: (
            title: "friends",
            description: "helloworld",
            thumbnail: UIImage(named: "rabbit")!,
            media: .URL(NSURL(string: "http://www.apple.com/cn")!)
        )))

        MonkeyKing.shareMessage(message) { success in
            print("shareURLToQQFriends success: \(success)")
        }
    }

    @IBAction func shareImageToQQZone(sender: UIButton) {

        MonkeyKing.registerAccount(.QQ(appID: qqAppID))

        let message = MonkeyKing.Message.QQ(.QZone(info: (
            title: "friends",
            description: "helloworld",
            thumbnail: UIImage(named: "rabbit")!,
            media: .Image(UIImage(named: "rabbit")!)
        )))

        MonkeyKing.shareMessage(message) { success in
            print("shareImageToQQZone success: \(success)")
        }
    }

    @IBAction func systemShare(sender: UIButton) {

        MonkeyKing.registerAccount(.WeChat(appID: weChatAppID))

        let shareURL = NSURL(string: "http://www.apple.com/cn/iphone/compare/")!

        let info = MonkeyKing.Info(
            title: "iPhone Compare",
            description: "iPhone 机型比较",
            thumbnail: UIImage(named: "rabbit"),
            media: .URL(shareURL)
        )

        let sessionMessage = MonkeyKing.Message.WeChat(.Session(info: info))

        let weChatSessionActivity = AnyActivity(
            type: "com.nixWork.China.WeChat.Session",
            title: NSLocalizedString("WeChat Session", comment: ""),
            image: UIImage(named: "wechat_session")!,
            canPerform: sessionMessage.canBeDelivered,
            perform: {
                MonkeyKing.shareMessage(sessionMessage) { success in
                    print("systemShare WeChat Session success: \(success)")
                }
            }
        )

        let timelineMessage = MonkeyKing.Message.WeChat(.Timeline(info: info))

        let weChatTimelineActivity = AnyActivity(
            type: "com.nixWork.China.WeChat.Timeline",
            title: NSLocalizedString("WeChat Timeline", comment: ""),
            image: UIImage(named: "wechat_timeline")!,
            canPerform: timelineMessage.canBeDelivered,
            perform: {
                MonkeyKing.shareMessage(timelineMessage) { success in
                    print("systemShare WeChat Timeline success: \(success)")
                }
            }
        )

        let activityViewController = UIActivityViewController(activityItems: [shareURL], applicationActivities: [weChatSessionActivity, weChatTimelineActivity])

        presentViewController(activityViewController, animated: true, completion: nil)
    }
}

