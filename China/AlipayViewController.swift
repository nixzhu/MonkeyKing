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

    override func viewDidLoad() {
        super.viewDidLoad()

        let account = MonkeyKing.Account.alipay(appID: Configs.Alipay.appID)
        MonkeyKing.registerAccount(account)
    }

    @IBAction func shareTextToAlipay(_ sender: UIButton) {
        let info = MonkeyKing.Info(
            title: "Friends Text, \(UUID().uuidString)",
            description: nil,
            thumbnail: nil,
            media: nil
        )
        self.shareInfo(info)
    }

    @IBAction func shareImageToAlipay(_ sender: UIButton) {
        let info = MonkeyKing.Info(
            title: nil,
            description: nil,
            thumbnail: nil,
            media: .image(UIImage(named: "rabbit")!)
        )
        self.shareInfo(info)
    }

    @IBAction func shareURLToAlipay(_ sender: UIButton) {
        let info = MonkeyKing.Info(
            title: "Friends URL, \(UUID().uuidString)",
            description: "Description URL, \(UUID().uuidString)",
            thumbnail: UIImage(named: "rabbit"),
            media: .url(URL(string: "http://soyep.com")!)
        )
        self.shareInfo(info)
    }

    fileprivate func shareInfo(_ info: MonkeyKing.Info) {
        let message = MonkeyKing.Message.alipay(.friends(info: info))
        MonkeyKing.shareMessage(message) { result in
            print("result: \(result)")
        }
    }

    // MARK: Pay

    @IBAction func pay(_ sender: UIButton) {

        do {
            let data = try NSURLConnection.sendSynchronousRequest(URLRequest(url: URL(string: "http://www.example.com/pay.php?payType=alipay")!), returning: nil)
            let urlString = String(data: data, encoding: String.Encoding.utf8)

            let order = MonkeyKing.Order.alipay(urlString: urlString!)

            MonkeyKing.payOrder(order) { result in
                print("result: \(result)")
            }

        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
}

