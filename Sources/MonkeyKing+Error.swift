//
//  MonkeyKing+Error.swift
//  MonkeyKing
//
//  Created by SlowWalker on 23/03/2017.
//  Copyright © 2017 nixWork. All rights reserved.
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
                case parseResponseFailed
                case unrecognizedErrorCode
                case connectFailed
                case invalidToken
            }
            var type: Type
            var responseData: [String: Any]?
        }
        case apiRequest(reason: APIRequestReason)
    }
}
