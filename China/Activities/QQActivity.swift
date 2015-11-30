//
//  QQActivity.swift
//  China
//
//  Created by NIX on 15/9/13.
//  Copyright © 2015年 nixWork. All rights reserved.
//

public class QQActivity: ShareActivity {

    enum Type {

        case Friends
        case QZone

        var type: String {
            switch self {
                case .Friends:
                    return "com.nixWork.MonkeyKing.QQ.Friends\(NSUUID().UUIDString)"
                case .QZone:
                    return "com.nixWork.MonkeyKing.QQ.Zone\(NSUUID().UUIDString)"
            }
        }

        var title: String {
            switch self {
                case .Friends:
                    return NSLocalizedString("QQ", comment: "")
                case .QZone:
                    return NSLocalizedString("QQ 空间", comment: "")
            }
        }

        var image: UIImage {
            switch self {
                case .Friends:
                    return UIImage(named: "sns_share_qq", inBundle: NSBundle(forClass: QQActivity.self), compatibleWithTraitCollection: nil)!
                case .QZone:
                    return UIImage(named: "sns_share_qzone", inBundle: NSBundle(forClass: QQActivity.self), compatibleWithTraitCollection: nil)!
            }
        }
    }

    public init(content: Content, serviceProvider: QQServiceProvider, completionHandler: ShareCompletionHandler? = nil) {

        let type: Type

        if let destination = serviceProvider.destination {
            switch destination {
                case .Friends:
                    type = .Friends
                case .QZone:
                    type = .QZone
            }
        }
        else {
            type = .Friends
        }

        super.init(type: type.type, title: type.title, image: type.image, content: content, serviceProvider: serviceProvider)
    }
}
