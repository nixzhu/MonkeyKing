//
//  PocketViewController.swift
//  China
//
//  Created by catch on 15/11/25.
//  Copyright © 2015年 nixWork. All rights reserved.
//

import UIKit
import MonkeyKing

class PocketViewController: UIViewController {

    let account = MonkeyKing.Account.pocket(appID: Configs.Pocket.appID)
    var accessToken: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        MonkeyKing.registerAccount(account)
    }

    // Save URL to Pocket
    @IBAction func saveButtonAction(_ sender: UIButton) {

        guard let accessToken = accessToken else {
            return
        }

        let addAPI = "https://getpocket.com/v3/add"
        let parameters = [
            "url": "http://tips.producter.io",
            "title": "Producter",
            "consumer_key": Configs.Pocket.appID,
            "access_token": accessToken
        ]

        SimpleNetworking.sharedInstance.request(addAPI, method: .post, parameters: parameters, encoding: .json) { (info, response, error) in
            guard let status = info?["status"] as? Int, status == 1 else {
                return
            }
            print("Pocket add url successfully")
        }

        // More API
        // https://getpocket.com/developer/docs/v3/add
    }

    // Pocket OAuth
    @IBAction func OAuth(_ sender: UIButton) {

        let requestAPI = "https://getpocket.com/v3/oauth/request"

        let parameters = [
            "consumer_key": Configs.Pocket.appID,
            "redirect_uri": Configs.Pocket.redirectURL
        ]

        print("S1: fetch requestToken")

        SimpleNetworking.sharedInstance.request(requestAPI, method: .post, parameters: parameters, encoding: .json) { [weak self] (info, response, error) in

            guard let strongSelf = self, let requestToken = info?["code"] as? String else {
                return
            }

            print("S2: OAuth by requestToken: \(requestToken)")

            MonkeyKing.oauth(for: .pocket(requestToken: requestToken)) { (dictionary, response, error) in

                guard error == nil else {
                    print(error)
                    return
                }

                let accessTokenAPI = "https://getpocket.com/v3/oauth/authorize"
                let parameters = [
                    "consumer_key": Configs.Pocket.appID,
                    "code": requestToken
                ]

                print("S3: fetch OAuth state")

                SimpleNetworking.sharedInstance.request(accessTokenAPI, method: .post, parameters: parameters, encoding: .json) { (info, response, error) in

                    print("S4: OAuth completion")

                    print("JSON: \(info)")

                    // If the HTTP status of the response is 200, then the request completed successfully.
                    print("response: \(response)")

                    strongSelf.accessToken = info?["access_token"] as? String
                }
            }
            
            // More details
            // Pocket Authentication API Documentation: https://getpocket.com/developer/docs/authentication
        }
    }
}
