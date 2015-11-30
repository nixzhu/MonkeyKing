//
//  PocketActivity.swift
//  China
//
//  Created by Shannon Wu on 11/30/15.
//  Copyright © 2015 nixWork. All rights reserved.
//

import Foundation

public class PocketActivity: ShareActivity {
    public init(content: Content, serviceProvider: PocketServiceProvider, completionHandler: ShareCompletionHandler? = nil) {
        super.init(
            type: "com.nixWork.MonkeyKing.Pocket\(NSUUID().UUIDString)",
            title: NSLocalizedString("Pocket", comment: ""),
            image: UIImage(named: "sns_share_pocket", inBundle: NSBundle(forClass: PocketActivity.self), compatibleWithTraitCollection: nil)!,
            content: content,
            serviceProvider: serviceProvider,
            completionHandler: completionHandler)
    }
}