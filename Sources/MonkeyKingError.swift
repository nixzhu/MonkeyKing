//
//  MonkeyKingError.swift
//  China
//
//  Created by Limon.F on 26/7/2017.
//  Copyright © 2017年 nixWork. All rights reserved.
//

import Foundation

extension MonkeyKing {

    public enum Error: Swift.Error {
        case noAccount
        case messageCanNotBeDelivered
        case invalidImageData

        public enum SDKReason {
            case unknown
            case invalidURLScheme
            case urlEncodeFailed
            case serializeFailed
        }
        case sdk(reason: SDKReason)

        public struct APIRequestReason {
            public enum `Type` {
                case unrecognizedError
                case connectFailed
                case invalidToken
            }
            public var type: Type
            public var responseData: [String: Any]?
        }
        case apiRequest(reason: APIRequestReason)
    }

    func errorReason(with responseData: [String: Any], at platform: SupportedPlatform) -> Error.APIRequestReason {

        let unrecognizedReason = Error.APIRequestReason(type: .unrecognizedError, responseData: responseData)
        switch platform {
        case .twitter:

            //ref: https://dev.twitter.com/overview/api/response-codes
            guard let errorCode = responseData["code"] as? Int else {
                return unrecognizedReason
            }
            switch errorCode {
            case 89, 99:
                return Error.APIRequestReason(type: .invalidToken, responseData: responseData)
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
                return Error.APIRequestReason(type: .invalidToken, responseData: responseData)
            default:
                return unrecognizedReason
            }

        default:
            return unrecognizedReason
        }
    }
}

extension MonkeyKing.Error: LocalizedError {

    public var errorDescription: String {
        switch self {
        case .invalidImageData:
            return "Convert image to data failed."
        case .noAccount:
            return "There no invalid developer account."
        case .messageCanNotBeDelivered:
            return "Message can't be delivered."
        case .apiRequest(reason: let reason):

            switch reason.type {
            case .invalidToken:
                return "The token is invalid or expired."
            case .connectFailed:
                return "Can't open the API link."
            default:
                return "API invoke failed."
            }
            
        default:
            return "Some problems happenned in MonkeyKing."
        }
    }
}
