//
//  AnyActivity.swift
//  MonkeyKing
//
//  Created by NIX on 15/9/11.
//  Copyright © 2015年 nixWork. All rights reserved.
//

import UIKit

open class AnyActivity: UIActivity {

    fileprivate let type: String
    fileprivate let title: String
    fileprivate let image: UIImage

    fileprivate let message: MonkeyKing.Message
    fileprivate let sharedCompletionHandler: MonkeyKing.SharedCompletionHandler

    public init(type: String, title: String, image: UIImage, message: MonkeyKing.Message, completionHandler: @escaping MonkeyKing.SharedCompletionHandler) {

        self.type = type
        self.title = title
        self.image = image

        self.message = message
        self.sharedCompletionHandler = completionHandler

        super.init()
    }

    override open class var activityCategory : UIActivityCategory {
        return .share
    }

    override open var activityType : String? {
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
        MonkeyKing.shareMessage(message, completionHandler: sharedCompletionHandler)
        activityDidFinish(true)
    }
}

