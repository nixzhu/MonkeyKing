//
//  ViewController.swift
//  China
//
//  Created by NIX on 15/9/11.
//  Copyright © 2015年 nixWork. All rights reserved.
//

import UIKit
import MonkeyKing


extension ViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)

        switch indexPath.row {
            case 0:
                cell.textLabel!.text = "WeChat"
            case 1:
                cell.textLabel!.text = "Weibo"
            case 2:
                cell.textLabel!.text = "QQ"
            case 3:
                cell.textLabel!.text = "System"
            default:
                break
        }

        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch indexPath.row {
            case 0:
                performSegueWithIdentifier("WeChat", sender: nil)
            case 1:
                performSegueWithIdentifier("Weibo", sender: nil)
            case 2:
                performSegueWithIdentifier("QQ", sender: nil)
            case 3:
                performSegueWithIdentifier("System", sender: nil)
            default:
                break
        }
    }

}

class ViewController: UIViewController {


    @IBAction func shareToWeiBo(sender: UIButton) {
        let account = MonkeyKing.Account.Weibo(appID: weiboAppID, appKey: weiboAppKey, redirectURL: weiboRedirectURL)
        MonkeyKing.registerAccount(account)

        MonkeyKing.OAuth(account) { (dictionary, response, error) -> Void in
            print(dictionary)
        }

//        let message = MonkeyKing.Message.Weibo(.Default(info: (
//            title: "Timeline",
//            description: "Hello Timeline",
//            thumbnail: nil,
//            media: nil
//        ), accessToken: "2.00qTjiwB0CG1KY8c0539cea8yRYRkC"))

//        let message = MonkeyKing.Message.Weibo(.Default(info: (
//            title: "News",
//            description: "Hello Apple",
//            thumbnail: UIImage(named: "rabbit"),
//            media: .URL(NSURL(string: "http://www.apple.com/cn")!)
//        ), accessToken: "2.00qTjiwB0CG1KY8c0539cea8yRYRkC"))

//        MonkeyKing.shareMessage(message) { success in
//            print("success: \(success)")
//        }

        //        MonkeyKing.oauth(account) { (dictionary, response, error) -> Void in
        //            print(dictionary)
        //        }
    }


    @IBAction func shareToWeChatSession(sender: UIButton) {

        let account = MonkeyKing.Account.WeChat(appID: weChatAppID, appKey: weChatAppKey)
        MonkeyKing.registerAccount(account)
        MonkeyKing.OAuth(account) { (dictionary, response, error) -> Void in
            print(dictionary)
        }

        //        MonkeyKing.registerAccount(.WeChat(appID: weChatAppID))
        //
        //        let message = MonkeyKing.Message.WeChat(.Session(info: (
        //            title: "Session",
        //            description: "Hello Session",
        //            thumbnail: UIImage(named: "rabbit"),
        //            media: .URL(NSURL(string: "http://www.apple.com/cn")!)
        //        )))

        //        MonkeyKing.shareMessage(message) { success in
        //            print("success: \(success)")
        //        }
    }

    @IBAction func shareToWeChatTimeline(sender: UIButton) {

        MonkeyKing.registerAccount(.WeChat(appID: weChatAppID, appKey: weChatAppKey))

        let message = MonkeyKing.Message.WeChat(.Timeline(info: (
            title: "Timeline",
            description: "Hello Timeline",
            thumbnail: nil,
            media: .Image(UIImage(named: "rabbit")!)
        )))

        MonkeyKing.shareMessage(message) { success in
            print("success: \(success)")
        }
    }

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
            canPerform: sessionMessage.canBeDelivered,
            perform: {
                MonkeyKing.shareMessage(sessionMessage) { success in
                    print("Session success: \(success)")
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
                    print("Timeline success: \(success)")
                }
            }
        )

        let activityViewController = UIActivityViewController(activityItems: [shareURL], applicationActivities: [weChatSessionActivity, weChatTimelineActivity])

        presentViewController(activityViewController, animated: true, completion: nil)
    }

    @IBAction func shareToQQFriends(sender: UIButton) {

        let account = MonkeyKing.Account.QQ(appID: qqAppID)
        MonkeyKing.registerAccount(account)
        MonkeyKing.OAuth(account) { (dictionary, response, error) -> Void in
            print(error)
        }


        //
        //        let message = MonkeyKing.Message.QQ(.Friends(info: (
        //            title: "friends",
        //            description: "helloworld",
        //            thumbnail: UIImage(named: "rabbit")!,
        //            media: .Image(UIImage(named: "rabbit")!)
        //        )))
        //
        //        MonkeyKing.shareMessage(message) { success in
        //            print("success: \(success)")
        //        }
        
        //        let message = MonkeyKing.Message.QQ(.Friends(info: (
        //            title: "friends",
        //            description: "helloworld",
        //            thumbnail: UIImage(named: "rabbit")!,
        //            media: .URL(NSURL(string: "http://www.apple.com/cn")!)
        //        )))
        //
        //        MonkeyKing.shareMessage(message) { success in
        //            print("success: \(success)")
        //        }
    }
    
}

