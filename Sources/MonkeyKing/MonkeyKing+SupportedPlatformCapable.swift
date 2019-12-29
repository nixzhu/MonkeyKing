
import Foundation

protocol SupportedPlatformCapable {

    var platform: MonkeyKing.SupportedPlatform { get }
}

extension MonkeyKing.Account: SupportedPlatformCapable {

    var platform: MonkeyKing.SupportedPlatform {
        switch self {
        case .weChat:
            return .weChat
        case .qq:
            return .qq
        case .weibo:
            return .weibo
        case .pocket:
            return .pocket
        case .alipay:
            return .alipay
        case .twitter:
            return .twitter
        }
    }
}

extension MonkeyKing.Message: SupportedPlatformCapable {

    var platform: MonkeyKing.SupportedPlatform {
        switch self {
        case .weChat:
            return .weChat
        case .qq:
            return .qq
        case .weibo:
            return .weibo
        case .alipay:
            return .alipay
        case .twitter:
            return .twitter
        }
    }
}

extension MonkeyKing.Order: SupportedPlatformCapable {

    var platform: MonkeyKing.SupportedPlatform {
        switch self {
        case .weChat:
            return .weChat
        case .alipay:
            return .alipay
        }
    }
}

extension MonkeyKing.Program: SupportedPlatformCapable {

    var platform: MonkeyKing.SupportedPlatform {
        switch self {
        case .weChat:
            return .weChat
        }
    }
}
