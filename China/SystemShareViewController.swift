
import UIKit
import MonkeyKing

class SystemShareViewController: UIViewController {

    @IBAction func systemShare(_ sender: UIButton) {
        MonkeyKing.registerAccount(.weChat(appID: Configs.Wechat.appID, appKey: Configs.Wechat.appKey))
        let shareURL = URL(string: "http://www.apple.com/cn/iphone/compare/")!
        let info = MonkeyKing.Info(
            title: "iPhone Compare",
            description: "iPhone 机型比较",
            thumbnail: UIImage(named: "rabbit"),
            media: .url(shareURL)
        )
        let sessionMessage = MonkeyKing.Message.weChat(.session(info: info))
        let weChatSessionActivity = AnyActivity(
            type: UIActivityType(rawValue: "com.nixWork.China.WeChat.Session"),
            title: NSLocalizedString("WeChat Session", comment: ""),
            image: UIImage(named: "wechat_session")!,
            message: sessionMessage,
            completionHandler: { success in
                print("Session success: \(success)")
            }
        )
        let timelineMessage = MonkeyKing.Message.weChat(.timeline(info: info))
        let weChatTimelineActivity = AnyActivity(
            type: UIActivityType(rawValue: "com.nixWork.China.WeChat.Timeline"),
            title: NSLocalizedString("WeChat Timeline", comment: ""),
            image: UIImage(named: "wechat_timeline")!,
            message: timelineMessage,
            completionHandler: { success in
                print("Timeline success: \(success)")
            }
        )
        let activityViewController = UIActivityViewController(activityItems: [shareURL], applicationActivities: [weChatSessionActivity, weChatTimelineActivity])
        present(activityViewController, animated: true, completion: nil)
    }
}
