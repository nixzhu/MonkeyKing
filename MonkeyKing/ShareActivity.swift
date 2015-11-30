//
//  AnyActivity.swift
//  MonkeyKing
//
//  Created by NIX on 15/9/11.
//  Copyright © 2015年 nixWork. All rights reserved.
//

import UIKit

public class ShareActivity: UIActivity {

    public var type: String
    public var title: String
    public var image: UIImage

    let content: Content
    var serviceProvider: ShareServiceProvider
    let completionHandler: ShareCompletionHandler?

    public init(type: String, title: String, image: UIImage, content: Content, serviceProvider: ShareServiceProvider, completionHandler: ShareCompletionHandler? = nil) {

        self.type = type
        self.title = title
        self.image = image

        self.content = content
        self.serviceProvider = serviceProvider
        self.completionHandler = completionHandler

        super.init()
    }

    override public class func activityCategory() -> UIActivityCategory {
        return .Share
    }

    override public func activityType() -> String? {
        return type
    }

    override public func activityTitle() -> String? {
        return title
    }

    override public func activityImage() -> UIImage? {
        return image
    }

    override public func canPerformWithActivityItems(activityItems: [AnyObject]) -> Bool {
        return serviceProvider.canShareContent(content)
    }

    override public func performActivity() {
        do {
            try MonkeyKing.shareContent(content, serviceProvider: serviceProvider, completionHandler: completionHandler)
        }
        catch _ {
            activityDidFinish(false)
        }
        activityDidFinish(true)
    }
}
