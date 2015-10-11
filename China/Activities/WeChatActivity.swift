//
//  WeChatActivity.swift
//  China
//
//  Created by NIX on 15/9/13.
//  Copyright © 2015年 nixWork. All rights reserved.
//

import MonkeyKing

class WeChatActivity: AnyActivity {

    enum Type {

        case Session
        case Timeline

        var type: String {
            switch self {
            case .Session:
                return "com.nixWork.China.WeChat.Session"
            case .Timeline:
                return "com.nixWork.China.WeChat.Timeline"
            }
        }

        var title: String {
            switch self {
            case .Session:
                return NSLocalizedString("WeChat Session", comment: "")
            case .Timeline:
                return NSLocalizedString("WeChat Timeline", comment: "")
            }
        }

        var image: UIImage {
            switch self {
            case .Session:
                return UIImage(named: "wechat_session")!
            case .Timeline:
                return UIImage(named: "wechat_timeline")!
            }
        }
    }

    init(type: Type, message: MonkeyKing.Message, finish: MonkeyKing.Finish) {

        MonkeyKing.registerAccount(.WeChat(appID: weChatAppID, appKey: ""))

        super.init(
            type: type.type,
            title: type.title,
            image: type.image,
            message: message,
            finish: finish
        )
    }
}

