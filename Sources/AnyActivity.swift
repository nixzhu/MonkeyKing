
import UIKit

open class AnyActivity: UIActivity {

    private let type: UIActivityType
    private let title: String
    private let image: UIImage

    private let message: MonkeyKing.Message
    private let completionHandler: MonkeyKing.DeliverCompletionHandler

    public init(type: UIActivityType, title: String, image: UIImage, message: MonkeyKing.Message, completionHandler: @escaping MonkeyKing.DeliverCompletionHandler) {
        self.type = type
        self.title = title
        self.image = image
        self.message = message
        self.completionHandler = completionHandler
        super.init()
    }

    override open class var activityCategory : UIActivityCategory {
        return .share
    }

    override open var activityType: UIActivityType? {
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
