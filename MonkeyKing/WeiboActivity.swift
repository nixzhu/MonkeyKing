//
//  WeiboActivity.swift
//  China
//
//  Created by Shannon Wu on 11/30/15.
//  Copyright © 2015 nixWork. All rights reserved.
//

import UIKit

public class WeiboActivity: ShareActivity {
    public init(content: Content, serviceProvider: WeiboServiceProvier, completionHandler: ShareCompletionHandler? = nil) {

        super.init(type: "com.nixWork.MonkeyKing.Weibo\(NSUUID().UUIDString)",
            title: NSLocalizedString("微博", comment: ""),
            image: UIImage(named: "sns_share_weibo", inBundle: NSBundle(forClass: WeiboActivity.self), compatibleWithTraitCollection: nil)!,
            content: content,
            serviceProvider: serviceProvider,
            completionHandler: completionHandler)
    }
}
