//
//  AlipayViewController.swift
//  China
//
//  Created by Cai Linfeng on 1/26/16.
//  Copyright © 2016 nixWork. All rights reserved.
//

import UIKit
import MonkeyKing

class AlipayViewController: UIViewController {
    let account = MonkeyKing.Account.Alipay(appID: Configs.Alipay.appID)

    override func viewDidLoad() {
        super.viewDidLoad()

        MonkeyKing.registerAccount(account)
    }

    @IBAction func shareTextToAlipay(sender: UIButton) {
        let info =  MonkeyKing.Info(
            title: "Friends Text, \(NSUUID().UUIDString)",
            description: nil,
            thumbnail: nil,
            media: nil
        )
        self.shareInfo(info)
    }

    @IBAction func shareImageToAlipay(sender: UIButton) {
        let info =  MonkeyKing.Info(
            title: nil,
            description: nil,
            thumbnail: nil,
            media: .Image(UIImage(named: "rabbit")!)
        )
        self.shareInfo(info)
    }

    @IBAction func shareURLToAlipay(sender: UIButton) {
        let info =  MonkeyKing.Info(
            title: "Friends URL, \(NSUUID().UUIDString)",
            description: "Description URL, \(NSUUID().UUIDString)",
            thumbnail: UIImage(named: "rabbit"),
            media: .URL(NSURL(string: "http://soyep.com")!)
        )
        self.shareInfo(info)
    }


    private func shareInfo(info: MonkeyKing.Info){
        let message = MonkeyKing.Message.Alipay(.Friends(info: info))
        MonkeyKing.shareMessage(message) { result in
            print("result: \(result)")
        }
    }


}
