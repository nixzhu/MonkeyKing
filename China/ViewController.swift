//
//  ViewController.swift
//  China
//
//  Created by NIX on 15/9/11.
//  Copyright © 2015年 nixWork. All rights reserved.
//

import UIKit
import MonkeyKing

extension ViewController: MKGNetworkingProtocol {

    func request(URLString: String, method: MKGMethod, parameters: [String: AnyObject]?, encoding: MKGParameterEncoding, headers: [String: String]?, completionHandler: MKGNetworkingResponseHandler) {
        let method = SimpleNetworking.Method(rawValue: method.rawValue)!
        var encoding = SimpleNetworking.ParameterEncoding.URL
        switch encoding {
            case .JSON:
                encoding = .JSON
            case .URL:
                encoding = .URL
            case .URLEncodedInURL:
                encoding = .URLEncodedInURL
        }

        SimpleNetworking.sharedInstance.request(URLString, method: method, parameters: parameters, encoding: encoding, headers: headers, completionHandler: completionHandler)
    }

    func upload(URLString: String, parameters: [String: AnyObject], completionHandler: MKGNetworkingResponseHandler) {
        SimpleNetworking.sharedInstance.upload(URLString, parameters: parameters, completionHandler: completionHandler)
    }
}

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        MonkeyKing.networkingDelegate = self
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
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
        case 4:
            cell.textLabel!.text = "Pocket"
        default:
            break
        }

        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        tableView.deselectRowAtIndexPath(indexPath, animated: true)

        switch indexPath.row {
        case 0:
            performSegueWithIdentifier("WeChat", sender: nil)
        case 1:
            performSegueWithIdentifier("Weibo", sender: nil)
        case 2:
            performSegueWithIdentifier("QQ", sender: nil)
        case 3:
            performSegueWithIdentifier("System", sender: nil)
        case 4:
            performSegueWithIdentifier("Pocket", sender: nil)
        default:
            break
        }
    }
}

