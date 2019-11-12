
import UIKit

open class AnyActivity: UIActivity {

    private let type: UIActivity.ActivityType
    private let title: String
    private let image: UIImage

    private let message: MonkeyKing.Message
    private let completionHandler: MonkeyKing.DeliverCompletionHandler

    public init(type: UIActivity.ActivityType, title: String, image: UIImage, message: MonkeyKing.Message, completionHandler: @escaping MonkeyKing.DeliverCompletionHandler) {
        self.type = type
        self.title = title
        self.image = image
        self.message = message
        self.completionHandler = completionHandler
        super.init()
    }

    override open class var activityCategory : UIActivity.Category {
        return .share
    }

    override open var activityType: UIActivity.ActivityType? {
        return type
    }

    override open  var activityTitle : String? {
        return title
    }

    override open var activityImage : UIImage? {
        return image
    }

    override open func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return message.canBeDelivered
    }

    override open func perform() {
        MonkeyKing.deliver(message, completionHandler: completionHandler)
        activityDidFinish(true)
    }
}
