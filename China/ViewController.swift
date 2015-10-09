//
//  ViewController.swift
//  China
//
//  Created by NIX on 15/9/11.
//  Copyright © 2015年 nixWork. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate  {

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

