//
//  MKError.swift
//  MonkeyKing
//
//  Created by SlowWalker on 23/03/2017.
//  Copyright © 2017 nixWork. All rights reserved.
//

import Foundation

// MARK: - Error

public enum MKError: Error {

    public enum SDKErrorDetails {
        case unknownError
        case invalidURLScheme
        case urlEncodeFailed
        case serializeFailed
    }

    public struct APIErrorDetails {

        public enum type {
            case parseResponseFailed
            case unrecognizedErrorCode
            case connectFailed
            case invalidToken
        }

        var type: type
        var responseData: [String: Any]?
    }

    case registerError
    case invalidImageData
    case sdkError(reason: SDKErrorDetails)
    case apiRequestError(reason: APIErrorDetails)

}
