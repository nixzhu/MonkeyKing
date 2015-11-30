//
//  URLHandler.swift
//  China
//
//  Created by Shannon Wu on 11/29/15.
//  Copyright © 2015 nixWork. All rights reserved.
//

import Foundation

struct URLHandler {
    static func openURL(URLString URLString: String) -> Bool {
        guard let URL = NSURL(string: URLString) else {
            return false
        }

        return UIApplication.sharedApplication().openURL(URL)
    }

    static func canOpenURL(URL: NSURL?) -> Bool {
        guard let URL = URL else {
            return false
        }

        return UIApplication.sharedApplication().canOpenURL(URL)
    }
}