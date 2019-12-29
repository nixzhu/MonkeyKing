
import Foundation

extension MonkeyKing {

    public class func openScheme(_ scheme: String, options: [UIApplication.OpenExternalURLOptionsKey: Any] = [:], completionHandler: OpenSchemeCompletionHandler? = nil) {

        shared.openSchemeCompletionHandler = completionHandler
        shared.deliverCompletionHandler = nil
        shared.payCompletionHandler = nil
        shared.oauthCompletionHandler = nil

        let handleErrorResult: () -> Void = {
            shared.openSchemeCompletionHandler = nil
            completionHandler?(.failure(.apiRequest(.unrecognizedError(response: nil))))
        }

        if let url = URL(string: scheme) {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: options) { flag in
                    if !flag {
                        handleErrorResult()
                    }
                }
            } else {
                let resutl = UIApplication.shared.openURL(url)
                if !resutl {
                    handleErrorResult()
                }
            }
        } else {
            handleErrorResult()
        }
    }
}
