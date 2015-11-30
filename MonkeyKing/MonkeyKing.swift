//
//  MonkeyKing.swift
//  MonkeyKing
//
//  Created by NIX on 15/9/11.
//  Copyright © 2015年 nixWork. All rights reserved.
//

import UIKit

public struct MonkeyKing {
    public static var serviceProvider: ShareServiceProvider?

    public static func shareContent(content: Content, serviceProvider: ShareServiceProvider, completionHandler: ShareCompletionHandler? = nil) throws {
        self.serviceProvider = serviceProvider

        func completionHandlerCleaner(succeed: Bool) {
            completionHandler?(succeed: succeed)
            MonkeyKing.serviceProvider = nil
        }

        do {
            try serviceProvider.shareContent(content, completionHandler: completionHandlerCleaner)
        }
        catch let error {
            MonkeyKing.serviceProvider = nil
            throw error
        }
    }

    public static func OAuth(serviceProvider: ShareServiceProvider, completionHandler: NetworkResponseHandler) throws {
        self.serviceProvider = serviceProvider

        func completionHandlerCleaner(dictionary: NSDictionary?, response: NSURLResponse?, error: NSError?) {
            completionHandler(dictionary, response, error)
            MonkeyKing.serviceProvider = nil
        }

        do {
            try serviceProvider.OAuth(completionHandler)
        }
        catch let error {
            MonkeyKing.serviceProvider = nil
            throw error
        }
    }

    public static func handleOpenURL(URL: NSURL) -> Bool {
        if let serviceProvider = serviceProvider {
            return serviceProvider.handleOpenURL(URL)
        }
        else {
            return false
        }
    }

}
