//
//  WeChatViewController.swift
//  China
//
//  Created by catch on 15/9/26.
//  Copyright © 2015年 nixWork. All rights reserved.
//

import UIKit
import MonkeyKing

let weChatAppID = "wx4634c56c1aed39f5"
let weChatAppKey = "8493fd2c782dd9b1dfdd724a6847dd28"

class WeChatViewController: UIViewController {

    let account = MonkeyKing.Account.WeChat(appID: weChatAppID, appKey: weChatAppKey)

    override func viewDidLoad() {
        super.viewDidLoad()
        MonkeyKing.registerAccount(account)
    }

    @IBAction func shareImageToTimeline(sender: UIButton) {

        let message = MonkeyKing.Message.WeChat(.Timeline(info: (
            title: nil,
            description: nil,
            thumbnail: nil,
            media: .Image(UIImage(named: "rabbit")!)
        )))

        MonkeyKing.shareMessage(message) { success in
            print("success: \(success)")
        }

    }

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
            title: "Title",
            description: "Description",
            thumbnail: UIImage(named: "rabbit"),
            media: .URL(NSURL(string: "http://www.apple.com/cn")!)
        )))

        MonkeyKing.shareMessage(message) { success in
            print("success: \(success)")
        }
    }


    // MARK: Session

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
            title: "Title",
            description: "description",
            thumbnail: UIImage(named: "rabbit"),
            media: .URL(NSURL(string: "http://www.apple.com/cn")!)
        )))

        MonkeyKing.shareMessage(message) { success in
            print("success: \(success)")
        }
    }

    @IBAction func OAuth(sender: UIButton) {
        MonkeyKing.OAuth(account) { (dictionary, response, error) -> Void in
            print("dictionary \(dictionary) error \(error)")
        }
    }
    
}
