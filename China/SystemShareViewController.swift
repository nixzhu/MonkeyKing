//
//  SystemShareViewController.swift
//  China
//
//  Created by Limon on 15/9/26.
//  Copyright © 2015年 nixWork. All rights reserved.
//

import UIKit
import MonkeyKing

class SystemShareViewController: UIViewController {

    @IBAction func systemShare(sender: UIButton) {

        MonkeyKing.registerAccount(.WeChat(appID: weChatAppID, appKey: weChatAppKey))

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
            message: sessionMessage,
            completionHandler: { success in
                print("Session success: \(success)")
            }
        )

        let timelineMessage = MonkeyKing.Message.WeChat(.Timeline(info: info))

        let weChatTimelineActivity = AnyActivity(
            type: "com.nixWork.China.WeChat.Timeline",
            title: NSLocalizedString("WeChat Timeline", comment: ""),
            image: UIImage(named: "wechat_timeline")!,
            message: timelineMessage,
            completionHandler: { success in
                print("Timeline success: \(success)")
            }
        )

        let activityViewController = UIActivityViewController(activityItems: [shareURL], applicationActivities: [weChatSessionActivity, weChatTimelineActivity])

        presentViewController(activityViewController, animated: true, completion: nil)
    }
}

