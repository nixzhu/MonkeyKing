//
//  QQViewController.swift
//  China
//
//  Created by Limon on 15/9/26.
//  Copyright © 2015年 nixWork. All rights reserved.
//

import UIKit
import MonkeyKing

let qqAppID = "1104881792"

class QQViewController: UIViewController {

    let account = MonkeyKing.Account.QQ(appID: qqAppID)

    override func viewDidLoad() {
        super.viewDidLoad()
        MonkeyKing.registerAccount(account)
    }

    // MARK: QQ Friends

    @IBAction func shareImageToQQ(sender: UIButton) {

        let message = MonkeyKing.Message.QQ(.Friends(info: (
            title: "friends",
            description: "helloworld",
            thumbnail: nil,
            media: .Image(UIImage(named: "rabbit")!)
        )))

        MonkeyKing.shareMessage(message) { success in
            print("success: \(success)")
        }
    }

    @IBAction func shareTextToQQ(sender: UIButton) {

        let message = MonkeyKing.Message.QQ(.Friends(info: (
            title: nil,
            description: "helloworld",
            thumbnail: nil,
            media: nil
        )))

        MonkeyKing.shareMessage(message) { success in
            print("success: \(success)")
        }
    }

    @IBAction func shareURLToQQ(sender: UIButton) {

        let message = MonkeyKing.Message.QQ(.Friends(info: (
            title: "friends",
            description: "apple.com",
            thumbnail: UIImage(named: "rabbit")!,
            media: .URL(NSURL(string: "http://www.apple.com/cn")!)
        )))

        MonkeyKing.shareMessage(message) { success in
            print("success: \(success)")
        }

    }

    // MARK: QZone

    @IBAction func shareImageToQZone(sender: UIButton) {

        let message = MonkeyKing.Message.QQ(.Zone(info: (
            title: "friends",
            description: "helloworld",
            thumbnail: nil,
            media: .Image(UIImage(named: "rabbit")!)
        )))

        MonkeyKing.shareMessage(message) { success in
            print("success: \(success)")
        }
    }

    @IBAction func shareTextToQZone(sender: UIButton) {

        let message = MonkeyKing.Message.QQ(.Zone(info: (
            title: nil,
            description: "helloworld",
            thumbnail: nil,
            media: nil
        )))

        MonkeyKing.shareMessage(message) { success in
            print("success: \(success)")
        }
    }

    @IBAction func shareURLToQZone(sender: UIButton) {

        let message = MonkeyKing.Message.QQ(.Zone(info: (
            title: "friends",
            description: "apple.com",
            thumbnail: UIImage(named: "rabbit")!,
            media: .URL(NSURL(string: "http://www.qq.com")!)
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

