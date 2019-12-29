
import Foundation

extension MonkeyKing {

    public enum Order {
        /// You can custom URL scheme. Default "ap" + String(appID)
        /// ref: https://doc.open.alipay.com/docs/doc.htm?spm=a219a.7629140.0.0.piSRlm&treeId=204&articleId=105295&docType=1
        case alipay(urlString: String)
        case weChat(urlString: String)

        public var canBeDelivered: Bool {
            let scheme: String
            switch self {
            case .alipay:
                scheme = "alipay://"
            case .weChat:
                scheme = "weixin://"
            }
            return shared.canOpenURL(urlString: scheme)
        }
    }

    public class func deliver(_ order: Order, completionHandler: @escaping PayCompletionHandler) {
        if !order.canBeDelivered {
            completionHandler(.failure(.noApp))
            return
        }
        shared.payCompletionHandler = completionHandler
        shared.oauthCompletionHandler = nil
        shared.deliverCompletionHandler = nil
        shared.openSchemeCompletionHandler = nil

        switch order {
        case .weChat(let urlString):
            openURL(urlString: urlString) { flag in
                if flag { return }
                completionHandler(.failure(.apiRequest(.unrecognizedError(response: nil))))
            }
        case .alipay(let urlString):
            openURL(urlString: urlString) { flag in
                if flag { return }
                completionHandler(.failure(.apiRequest(.unrecognizedError(response: nil))))
            }
        }
    }
}
