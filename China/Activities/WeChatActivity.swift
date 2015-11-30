//
//  WeChatActivity.swift
//  China
//
//  Created by NIX on 15/9/13.
//  Copyright © 2015年 nixWork. All rights reserved.
//

public class WeChatActivity: ShareActivity {

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
                    return UIImage(named: "sns_share_session", inBundle: NSBundle(forClass: WeChatActivity.self), compatibleWithTraitCollection: nil)!
                case .Timeline:
                    return UIImage(named: "sns_share_moments", inBundle: NSBundle(forClass: WeChatActivity.self), compatibleWithTraitCollection: nil)!
            }
        }
    }

    public init(content: Content, serviceProvider: WeChatServiceProvier, completionHandler: ShareCompletionHandler? = nil) {

        let type: Type
        if let destination = serviceProvider.destination {
            switch destination {
                case .Session:
                    type = .Session
                case .Timeline:
                    type = .Timeline
            }
        }
        else {
            type = .Timeline
        }

        super.init(type: type.type, title: type.title, image: type.image, content: content, serviceProvider: serviceProvider)
    }
}

