//
//  MonkeyKing+WeChatUniversalLink.swift
//  MonkeyKing
//
//  Created by Lex on 2020/6/11.
//  Copyright © 2020 nixWork. All rights reserved.
//

import Foundation
import Security
import CommonCrypto


extension MonkeyKing {

    private static var wechatAccount: String {
        "WeChatOpenSDKKeyChainAccount"
    }

    private static var wechatServiceName: String {
        "WeChatOpenSDKKeyChainService_\(Bundle.main.bundleIdentifier ?? "")"
    }

    static var lastMessage: Message? {
        get {
            _lastMessage
        }
        set {
            _lastMessage = newValue
        }
    }

    // NOTE: Since the SHA1 algorithm is not reversible, it's not necessary to follow the original contentID in WechatOpenSDK
    // NSString(format: "%@_%p_%@", timeIntervalSince1970, SendMessageToWXRed, autoIncreaseId)
    static var wechatContextId: String {
        _autoIncreaseId += 1
        let str = String(format: "%f_%f", Date().timeIntervalSince1970, _autoIncreaseId)
        return str.sha1()
    }

    static var wechatAuthToken: String? {
        get {
            let query = [
                kSecAttrService as String: wechatServiceName,
                kSecAttrAccount as String: wechatAccount,
                kSecClass as String: kSecClassGenericPassword,
                kSecMatchLimit as String: kSecMatchLimitOne,
                kSecReturnData as String: true,
                kSecReturnAttributes as String: true
            ] as CFDictionary


            var queryResult: AnyObject?
            let status = withUnsafeMutablePointer(to: &queryResult) {
                SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
            }

            guard status != errSecItemNotFound else { return nil }
            guard status == noErr else { return nil }

            guard let existingItem = queryResult as? [String: AnyObject],
                let passwordData = existingItem[kSecValueData as String] as? Data,
                let password = String(data: passwordData, encoding: String.Encoding.utf8)
            else {
                return nil
            }
            return password
        }
        set {
            var query: [String: Any] = [
                kSecAttrService as String: wechatServiceName,
                kSecAttrAccount as String: wechatAccount,
                kSecClass as String: kSecClassGenericPassword
            ]

            if let newValue = newValue, let valueData = newValue.data(using: .utf8, allowLossyConversion: false) {
                SecItemDelete(query as CFDictionary)

                query[String(kSecValueData)] = valueData
                SecItemAdd(query as CFDictionary, nil)
            } else {
                SecItemDelete(query as CFDictionary)
            }
        }
    }

    func wechatUniversalLink(of command: String) -> String? {
        guard
            #available(iOS 10.0, *),
            let account = MonkeyKing.shared.accountSet[.weChat],
            account.universalLink != nil
        else {
            return nil
        }

        let appID = account.appID
        let contextId = MonkeyKing.wechatContextId
        let bundleId = Bundle.main.bundleIdentifier ?? ""
        let allowedCharacterSet = CharacterSet(charactersIn: "!*'();:@&=+$,/?%#[] ^").inverted

        if  let authToken = MonkeyKing.wechatAuthToken,
            let authTokenEncoded = NSString(string: authToken).addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)
        {
            return "https://help.wechat.com/app/\(appID)/\(command)/?wechat_auth_token=\(authTokenEncoded)&wechat_auth_context_id=\(contextId)&wechat_app_bundleId=\(bundleId)"
        } else {
            return "https://help.wechat.com/app/\(appID)/\(command)/?wechat_auth_context_id=\(contextId)&wechat_app_bundleId=\(bundleId)"
        }
    }

}

extension String {

    // NOTE: Obviously, we don't even have to use CommonCrypto
    // In order to reduce the package size, we'll replace this implenmentation some day
    func sha1() -> String {
        let data = Data(utf8)
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA1($0.baseAddress, CC_LONG(data.count), &digest)
        }
        let hexBytes = digest.map { String(format: "%02hhx", $0) }
        return hexBytes.joined()
    }
}

extension Data {
    var hexDescription: String {
        reduce("") { $0 + String(format: "%02x", $1) }
    }
}

private var _autoIncreaseId: UInt64 = 0
private var _lastMessage: MonkeyKing.Message?
