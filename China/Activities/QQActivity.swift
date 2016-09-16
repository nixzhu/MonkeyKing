//
//  QQActivity.swift
//  China
//
//  Created by NIX on 15/9/13.
//  Copyright © 2015年 nixWork. All rights reserved.
//

import MonkeyKing

class QQActivity: AnyActivity {

    enum `Type` {

        case friends
        case zone

        var activityType: UIActivityType {
            switch self {
            case .friends:
                return UIActivityType(rawValue: "com.nixWork.China.QQ.Friends")
            case .zone:
                return UIActivityType(rawValue: "com.nixWork.China.QQ.Zone")
            }
        }

        var title: String {
            switch self {
            case .friends:
                return NSLocalizedString("QQ Friends", comment: "")
            case .zone:
                return NSLocalizedString("QQ Zone", comment: "")
            }
        }

        var image: UIImage {
            switch self {
            case .friends:
                return UIImage(named: "wechat_session")! // TODO: qq_friends
            case .zone:
                return UIImage(named: "wechat_timeline")! // TODO: qq_zone
            }
        }
    }

    init(type: Type, message: MonkeyKing.Message, completionHandler: @escaping MonkeyKing.ShareCompletionHandler) {

        MonkeyKing.registerAccount(.qq(appID: Configs.QQ.appID))

        super.init(
            type: type.activityType,
            title: type.title,
            image: type.image,
            message: message,
            completionHandler: completionHandler
        )
    }
}

