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
        MonkeyKing.shareMessage(.WeChat(.Session)) { success in
            print("success \(success)")
        }
    }
}

