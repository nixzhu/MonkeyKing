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
            title: "Session",
            description: "Hello Session",
            thumbnail: UIImage(named: "rabbit"),
            media: .URL(shareURL)
        )

        let message = MonkeyKing.Message.WeChat(.Session(info))

        let weChatSessionActivity = AnyActivity(
            type: "com.nixWork.China.WeChat.Session",
            title: NSLocalizedString("WeChat Session", comment: ""),
            image: UIImage(named: "wechat_session")!,
            canPerform: message.canBeDelivered,
            perform: {
                MonkeyKing.shareMessage(message) { success in
                    print("success: \(success)")
                }
            }
        )

        let activityViewController = UIActivityViewController(activityItems: [shareURL], applicationActivities: [weChatSessionActivity])

        presentViewController(activityViewController, animated: true, completion: nil)
    }
}

