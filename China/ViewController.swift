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
            title: "Test",
            description: "Hello World",
            thumbnail: nil,
            media: .URL(NSURL(string: "http://baidu.com")!)
        )

        let message = MonkeyKing.Message.WeChat(.Session(info))

        MonkeyKing.shareMessage(message) { success in
            print("success \(success)")
        }
    }
}

