//
//  AnyActivity.swift
//  MonkeyKing
//
//  Created by NIX on 15/9/11.
//  Copyright © 2015年 nixWork. All rights reserved.
//

import UIKit

open class AnyActivity: UIActivity {

    fileprivate let type: UIActivityType
    fileprivate let title: String
    fileprivate let image: UIImage

    fileprivate let message: MonkeyKing.Message
    fileprivate let shareCompletionHandler: MonkeyKing.ShareCompletionHandler

    public init(type: UIActivityType, title: String, image: UIImage, message: MonkeyKing.Message, completionHandler: @escaping MonkeyKing.ShareCompletionHandler) {

        self.type = type
        self.title = title
        self.image = image

        self.message = message
        self.shareCompletionHandler = completionHandler

        super.init()
    }

    override open class var activityCategory : UIActivityCategory {
        return .share
    }

    override open var activityType: UIActivityType? {
        return type
    }

    override open  var activityTitle : String? {
        return title
    }

    override open var activityImage : UIImage? {
        return image
    }

    override open func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return message.canBeDelivered
    }

    override open func perform() {
        MonkeyKing.shareMessage(message, completionHandler: shareCompletionHandler)
        activityDidFinish(true)
    }
}

