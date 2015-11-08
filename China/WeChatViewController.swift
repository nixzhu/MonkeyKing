//
//  WeChatViewController.swift
//  China
//
//  Created by Limon on 15/9/26.
//  Copyright © 2015年 nixWork. All rights reserved.
//

import UIKit
import MonkeyKing

let weChatAppID = "wx4868b35061f87885"
let weChatAppKey = "64020361b8ec4c99936c0e3999a9f249"

class WeChatViewController: UIViewController {

    let account = MonkeyKing.Account.WeChat(appID: weChatAppID, appKey: weChatAppKey)

    override func viewDidLoad() {
        super.viewDidLoad()
        MonkeyKing.registerAccount(account)
    }

    // MARK: Timeline

    @IBAction func shareTextToTimeline(sender: UIButton) {

        let message = MonkeyKing.Message.WeChat(.Timeline(info: (
            title: "Timeline Text",
            description: nil,
            thumbnail: nil,
            media: nil
        )))

        MonkeyKing.shareMessage(message) { success in
            print("success: \(success)")
        }
    }

    @IBAction func shareURLToTimeline(sender: UIButton) {

        let message = MonkeyKing.Message.WeChat(.Timeline(info: (
            title: "Title URL",
            description: "Description URL",
            thumbnail: UIImage(named: "rabbit"),
            media: .URL(NSURL(string: "http://www.apple.com/cn")!)
        )))

        MonkeyKing.shareMessage(message) { success in
            print("success: \(success)")
        }
    }

    @IBAction func shareImageToTimeline(sender: UIButton) {

        let message = MonkeyKing.Message.WeChat(.Timeline(info: (
            title: nil,
            description: nil,
            thumbnail: UIImage(named: "rabbit"),
            media: .Image(UIImage(named: "rabbit")!)
        )))

        MonkeyKing.shareMessage(message) { success in
            print("success: \(success)")
        }
    }

    @IBAction func shareMusicToTimeline(sender: UIButton) {

        let message = MonkeyKing.Message.WeChat(.Timeline(info: (
            title: "Title Music",
            description: "Description Music",
            thumbnail: UIImage(named: "rabbit"),
            media: .Audio(audioURL: NSURL(string: "http://stream20.qqmusic.qq.com/32464723.mp3")!, linkURL: NSURL(string: "http://www.apple.com/cn")!)
        )))

        MonkeyKing.shareMessage(message) { success in
            print("success: \(success)")
        }
    }

    @IBAction func shareVideoToTimeline(sender: UIButton) {

        let message = MonkeyKing.Message.WeChat(.Timeline(info: (
            title: "Title Video",
            description: "Description Video",
            thumbnail: UIImage(named: "rabbit"),
            media: .Video(NSURL(string: "http://v.youku.com/v_show/id_XNTUxNDY1NDY4.html")!)
        )))

        MonkeyKing.shareMessage(message) { success in
            print("success: \(success)")
        }
    }

    // MARK: Session

    @IBAction func shareTextToSession(sender: UIButton) {

        let message = MonkeyKing.Message.WeChat(.Session(info: (
            title: "Session Text",
            description: nil,
            thumbnail: nil,
            media: nil)
        ))

        MonkeyKing.shareMessage(message) { success in
            print("success: \(success)")
        }
    }

    @IBAction func shareURLToSession(sender: UIButton) {

        let message = MonkeyKing.Message.WeChat(.Session(info: (
            title: "Title URL",
            description: "description URL",
            thumbnail: UIImage(named: "rabbit"),
            media: .URL(NSURL(string: "http://www.apple.com/cn")!)
        )))

        MonkeyKing.shareMessage(message) { success in
            print("success: \(success)")
        }
    }

    @IBAction func shareImageToSession(sender: UIButton) {

        let message = MonkeyKing.Message.WeChat(.Session(info: (
            title: nil,
            description: nil,
            thumbnail: UIImage(named: "rabbit"),
            media: .Image(UIImage(named: "rabbit")!)
        )))

        MonkeyKing.shareMessage(message) { success in
            print("success: \(success)")
        }
    }

    @IBAction func shareMusicToSession(sender: UIButton) {

        let message = MonkeyKing.Message.WeChat(.Session(info: (
            title: "Title Music",
            description: "Description Music",
            thumbnail: UIImage(named: "rabbit"),
            media: .Audio(audioURL: NSURL(string: "http://stream20.qqmusic.qq.com/32464723.mp3")!, linkURL: NSURL(string: "http://www.apple.com/cn")!)
        )))

        MonkeyKing.shareMessage(message) { success in
            print("success: \(success)")
        }
    }

    @IBAction func shareVideoToSession(sender: UIButton) {

        let message = MonkeyKing.Message.WeChat(.Session(info: (
            title: "Title Video",
            description: "Description Video",
            thumbnail: UIImage(named: "rabbit"),
            media: .Video(NSURL(string: "http://v.youku.com/v_show/id_XNTUxNDY1NDY4.html")!)
        )))

        MonkeyKing.shareMessage(message) { success in
            print("success: \(success)")
        }
    }

    // MARK: OAuth

    @IBAction func OAuth(sender: UIButton) {

        MonkeyKing.OAuth(account) { (dictionary, response, error) -> Void in
            print("dictionary \(dictionary) error \(error)")
        }
    }
}

