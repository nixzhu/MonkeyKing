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

        let shareURL = NSURL(string: "http://www.apple.com/cn/iphone/compare/")!

        var content = Content()
        content.title = "iPhone Compare"
        content.description = "iPhone 机型比较"
        content.thumbnail = UIImage(named: "rabbit")
        content.media = .URL(shareURL)


        let weChatSessionActivity = WeChatActivity(content: content, serviceProvider: WeChatServiceProvier(appID: weChatAppID, appKey: weChatAppKey, destination: .Session))
        let weChatTimelineActivity = WeChatActivity(content: content, serviceProvider: WeChatServiceProvier(appID: weChatAppID, appKey: weChatAppKey, destination: .Timeline))
        let qzonActivity = QQActivity(content: content, serviceProvider: QQServiceProvider(appID: qqAppID, destination: .QZone))
        let qqActivity = QQActivity(content: content, serviceProvider: QQServiceProvider(appID: qqAppID, destination: .Friends))


        let activityViewController = UIActivityViewController(activityItems: [shareURL], applicationActivities: [weChatSessionActivity, weChatTimelineActivity, qzonActivity, qqActivity])
        presentViewController(activityViewController, animated: true, completion: nil)
    }
}

