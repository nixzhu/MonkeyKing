//
//  QQActivity.swift
//  China
//
//  Created by NIX on 15/9/13.
//  Copyright © 2015年 nixWork. All rights reserved.
//

import MonkeyKing

class QQActivity: AnyActivity {

    enum Type {

        case Friends
        case Zone

        var type: String {
            switch self {
            case .Friends:
                return "com.nixWork.China.QQ.Friends"
            case .Zone:
                return "com.nixWork.China.QQ.Zone"
            }
        }

        var title: String {
            switch self {
            case .Friends:
                return NSLocalizedString("QQ Friends", comment: "")
            case .Zone:
                return NSLocalizedString("QQ Zone", comment: "")
            }
        }

        var image: UIImage {
            switch self {
            case .Friends:
                return UIImage(named: "wechat_session")! // TODO:
            case .Zone:
                return UIImage(named: "wechat_timeline")! // TODO:
            }
        }
    }

    init(type: Type, message: MonkeyKing.Message, completionHandler: MonkeyKing.SharedCompletionHandler) {

        MonkeyKing.registerAccount(.QQ(appID: qqAppID))

        super.init(
            type: type.type,
            title: type.title,
            image: type.image,
            message: message,
            completionHandler: completionHandler
        )
    }
}

