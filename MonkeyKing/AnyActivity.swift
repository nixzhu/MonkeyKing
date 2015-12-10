//
//  AnyActivity.swift
//  MonkeyKing
//
//  Created by NIX on 15/9/11.
//  Copyright © 2015年 nixWork. All rights reserved.
//

import UIKit

public class AnyActivity: UIActivity {

    private let type: String
    private let title: String
    private let image: UIImage

    private let message: MonkeyKing.Message
    private let sharedCompletionHandler: MonkeyKing.SharedCompletionHandler

    public init(type: String, title: String, image: UIImage, message: MonkeyKing.Message, completionHandler: MonkeyKing.SharedCompletionHandler) {

        self.type = type
        self.title = title
        self.image = image

        self.message = message
        self.sharedCompletionHandler = completionHandler

        super.init()
    }

    override public class func activityCategory() -> UIActivityCategory {
        return .Share
    }

    override public func activityType() -> String? {
        return type
    }

    override public  func activityTitle() -> String? {
        return title
    }

    override public func activityImage() -> UIImage? {
        return image
    }

    override public func canPerformWithActivityItems(activityItems: [AnyObject]) -> Bool {
        return message.canBeDelivered
    }

    override public func performActivity() {
        MonkeyKing.shareMessage(message, completionHandler: sharedCompletionHandler)
        activityDidFinish(true)
    }
}

