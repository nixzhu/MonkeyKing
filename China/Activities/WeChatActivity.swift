
import MonkeyKing

class WeChatActivity: AnyActivity {

    enum `Type` {
        case session
        case timeline

        var activityType: UIActivityType {
            switch self {
            case .session:
                return UIActivityType(rawValue: "com.nixWork.China.WeChat.Session")
            case .timeline:
                return UIActivityType(rawValue: "com.nixWork.China.WeChat.Timeline")
            }
        }

        var title: String {
            switch self {
            case .session:
                return NSLocalizedString("WeChat Session", comment: "")
            case .timeline:
                return NSLocalizedString("WeChat Timeline", comment: "")
            }
        }

        var image: UIImage {
            switch self {
            case .session:
                return UIImage(named: "wechat_session")!
            case .timeline:
                return UIImage(named: "wechat_timeline")!
            }
        }
    }

    init(type: Type, message: MonkeyKing.Message, completionHandler: @escaping MonkeyKing.DeliverCompletionHandler) {
        MonkeyKing.registerAccount(.weChat(appID: Configs.WeChat.appID, appKey: nil, miniAppID: nil))
        super.init(
            type: type.activityType,
            title: type.title,
            image: type.image,
            message: message,
            completionHandler: completionHandler
        )
    }
}
