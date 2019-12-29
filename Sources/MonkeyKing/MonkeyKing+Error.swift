
import UIKit

extension MonkeyKing {

    public enum Error: Swift.Error {

        public enum ResourceReason {
            case invalidImageData
            case missingTitle
            case missingDescription
            case missingThumbnail
            case missingMedia
            case imageTooBig
            case textTooLong
        }

        public enum SDKReason {
            case invalidURLScheme
            case urlEncodeFailed
            case urlDecodeFailed
            case serializeFailed
            case deserializeFailed
            case other(code: String)
        }

        public enum APIRequestReason {
            case unrecognizedError(response: ResponseJSON?)
            case connectFailed
            case invalidToken
            case invalidParameter
            case missingParameter
        }

        case noApp
        case noAccount
        case userCancelled
        case resource(ResourceReason)
        case sdk(SDKReason)
        case apiRequest(APIRequestReason)
    }

    func errorReason(with responseData: [String: Any], at platform: SupportedPlatform) -> Error {
        let unrecognizedReason = Error.apiRequest(.unrecognizedError(response: responseData))
        switch platform {
        case .twitter:
            // ref: https://dev.twitter.com/overview/api/response-codes
            guard let errorCode = responseData["code"] as? Int else {
                return unrecognizedReason
            }
            switch errorCode {
            case 89, 99:
                return Error.apiRequest(.invalidToken)
            default:
                return unrecognizedReason
            }
        case .weibo:
            // ref: http://open.weibo.com/wiki/Error_code
            guard let errorCode = responseData["error_code"] as? Int else {
                return unrecognizedReason
            }
            switch errorCode {
            case 21314, 21315, 21316, 21317, 21327, 21332:
                return Error.apiRequest(.invalidToken)
            default:
                return unrecognizedReason
            }
        default:
            return unrecognizedReason
        }
    }
}
