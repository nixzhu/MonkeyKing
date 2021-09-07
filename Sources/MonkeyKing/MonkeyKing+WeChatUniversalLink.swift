
import UIKit
import Security

extension MonkeyKing {

    private static var wechatAccount: String {
        "WeChatOpenSDKKeyChainAccount"
    }

    private static var wechatServiceName: String {
        "WeChatOpenSDKKeyChainService_\(Bundle.main.bundleIdentifier ?? "")"
    }

    static var lastMessage: Message? {
        get {
            return _lastMessage
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

    func wechatUniversalLink(of command: String, items: [URLQueryItem] = []) -> URL? {
        guard let account = MonkeyKing.shared.accountSet[.weChat],
              account.universalLink != nil else {
            return nil
        }

        let appID = account.appID
        let contextId = MonkeyKing.wechatContextId
        let bundleId = Bundle.main.bundleIdentifier ?? ""
        let allowedCharacterSet = CharacterSet(charactersIn: "!*'();:@&=+$,/?%#[] ^").inverted

        var queryItems = [
            URLQueryItem(name: "wechat_auth_context_id", value: contextId),
            URLQueryItem(name: "wechat_app_bundleId", value: bundleId)
        ]
        queryItems.append(contentsOf: items)

        var urlComponents = URLComponents(string: "https://help.wechat.com/app/\(appID)/\(command)/")
        urlComponents?.queryItems = queryItems
        return urlComponents?.url
    }

    func setPasteboard(of appId: String, with content: [String: Any]) {
        var weChatMessageInfo: [String: Any] = [
            "result": "1",
            "sdkver": "1.9.2",
            "returnFromApp": "0",
        ]

        content.forEach { (key, value) in
            weChatMessageInfo[key] = value
        }

        var weChatMessage: [String: Any] = [appId: weChatMessageInfo]
        if let oldText = UIPasteboard.general.oldText {
            weChatMessage["old_text"] = oldText
        }

        guard let data = try? PropertyListSerialization.data(fromPropertyList: weChatMessage, format: .binary, options: .init()) else { return }
        UIPasteboard.general.setData(data, forPasteboardType: "content")
    }
}

private var _autoIncreaseId: UInt64 = 0
private var _lastMessage: MonkeyKing.Message?
