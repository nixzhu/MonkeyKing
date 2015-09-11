//
//  ViewController.swift
//  China
//
//  Created by NIX on 15/9/11.
//  Copyright © 2015年 nixWork. All rights reserved.
//

import UIKit
import MonkeyKing

class ViewController: UIViewController {

    @IBAction func shareToWeChatSession(sender: UIButton) {

        let info = MonkeyKing.Message.WeChatType.Info(
            title: "Session",
            description: "Hello Session",
            thumbnail: UIImage(named: "rabbit"),
            media: .URL(NSURL(string: "http://baidu.com")!)
        )

        let message = MonkeyKing.Message.WeChat(.Session(info))

        MonkeyKing.shareMessage(message) { success in
            print("success: \(success)")
        }
    }

    @IBAction func shareToWeChatTimeline(sender: UIButton) {

        let info = MonkeyKing.Message.WeChatType.Info(
            title: "Timeline",
            description: "Hello Timeline",
            thumbnail: nil,
            media: .Image(UIImage(named: "rabbit")!)
        )

        let message = MonkeyKing.Message.WeChat(.Timeline(info))

        MonkeyKing.shareMessage(message) { success in
            print("success: \(success)")
        }
    }

    @IBAction func systemShare(sender: UIButton) {

        let shareURL = NSURL(string: "http://www.apple.com/cn")!

        let info = MonkeyKing.Message.WeChatType.Info(
            title: "New iPhones",
            description: "Order begin at 3 PM tomorrow.",
            thumbnail: UIImage(named: "rabbit"),
            media: .URL(shareURL)
        )

        let sessionMessage = MonkeyKing.Message.WeChat(.Session(info))

        let weChatSessionActivity = AnyActivity(
            type: "com.nixWork.China.WeChat.Session",
            title: NSLocalizedString("WeChat Session", comment: ""),
            image: UIImage(named: "wechat_session")!,
            canPerform: sessionMessage.canBeDelivered,
            perform: {
                MonkeyKing.shareMessage(sessionMessage) { success in
                    print("Session success: \(success)")
                }
            }
        )

        let timelineMessage = MonkeyKing.Message.WeChat(.Timeline(info))

        let weChatTimelineActivity = AnyActivity(
            type: "com.nixWork.China.WeChat.Timeline",
            title: NSLocalizedString("WeChat Timeline", comment: ""),
            image: UIImage(named: "wechat_timeline")!,
            canPerform: timelineMessage.canBeDelivered,
            perform: {
                MonkeyKing.shareMessage(timelineMessage) { success in
                    print("Timeline success: \(success)")
                }
            }
        )

        let activityViewController = UIActivityViewController(activityItems: [shareURL], applicationActivities: [weChatSessionActivity, weChatTimelineActivity])

        presentViewController(activityViewController, animated: true, completion: nil)
    }
}

