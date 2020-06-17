
import Foundation

extension MonkeyKing {

    public class func handleOpenURL(_ url: URL) -> Bool {

        guard let urlScheme = url.scheme else { return false }

        // WeChat
        if urlScheme.hasPrefix("wx") {
            let urlString = url.absoluteString
            // OAuth
            if urlString.contains("state=Weixinauth") {
                let queryDictionary = url.monkeyking_queryDictionary
                guard let code = queryDictionary["code"] else {
                    shared.oauthFromWeChatCodeCompletionHandler = nil
                    return false
                }
                // Login Succcess
                if let halfOauthCompletion = shared.oauthFromWeChatCodeCompletionHandler {
                    halfOauthCompletion(.success(code))
                    shared.oauthFromWeChatCodeCompletionHandler = nil
                } else {
                    fetchWeChatOAuthInfoByCode(code: code) { result in
                        shared.oauthCompletionHandler?(result)
                    }
                }
                return true
            }
            // SMS OAuth
            if urlString.contains("wapoauth") {
                let queryDictionary = url.monkeyking_queryDictionary
                guard let m = queryDictionary["m"] else { return false }
                guard let t = queryDictionary["t"] else { return false }
                guard let account = shared.accountSet[.weChat] else { return false }
                let appID = account.appID
                let urlString = "https://open.weixin.qq.com/connect/smsauthorize?appid=\(appID)&redirect_uri=\(appID)%3A%2F%2Foauth&response_type=code&scope=snsapi_message,snsapi_userinfo,snsapi_friend,snsapi_contact&state=xxx&uid=1926559385&m=\(m)&t=\(t)"
                addWebView(withURLString: urlString)
                return true
            }
            // Pay
            if urlString.contains("://pay/") {
                let queryDictionary = url.monkeyking_queryDictionary

                guard let ret = queryDictionary["ret"] else {
                    shared.payCompletionHandler?(.failure(.apiRequest(.missingParameter)))
                    return false
                }

                let result = (ret == "0")

                if result {
                    shared.payCompletionHandler?(.success(()))
                } else {
                    shared.payCompletionHandler?(.failure(.apiRequest(.unrecognizedError(response: queryDictionary))))
                }

                return result
            }

            if let data = UIPasteboard.general.data(forPasteboardType: "content") {
                if let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] {

                    guard
                        let account = shared.accountSet[.weChat],
                        let info = dict[account.appID] as? [String: Any],
                        let result = info["result"] as? String,
                        let resultCode = Int(result) else {
                        return false
                    }

                    // OAuth Failed
                    if let state = info["state"] as? String, state == "Weixinauth", resultCode != 0 {
                        let error: Error = resultCode == -2
                            ? .userCancelled
                            : .sdk(.other(code: result))
                        if let oauthCompletionHandler = shared.oauthCompletionHandler {
                            oauthCompletionHandler(.failure(error))
                        }
                        
                        if let oauthFromWeChatCodeCompletionHandler = shared.oauthFromWeChatCodeCompletionHandler {
                            oauthFromWeChatCodeCompletionHandler(.failure(error))
                        }
                        return false
                    }

                    let success = (resultCode == 0)

                    // Share or Launch Mini App
                    let messageExtKey = "messageExt"
                    if success {
                        if let messageExt = info[messageExtKey] as? String {
                            shared.launchFromWeChatMiniAppCompletionHandler?(.success(messageExt))
                        } else {
                            shared.deliverCompletionHandler?(.success(nil))
                        }
                    } else {
                        if let messageExt = info[messageExtKey] as? String {
                            shared.launchFromWeChatMiniAppCompletionHandler?(.success(messageExt))
                            return true
                        } else {
                            let error: Error = resultCode == -2
                                ? .userCancelled
                                : .sdk(.other(code: result))
                            shared.deliverCompletionHandler?(.failure(error))
                        }
                    }

                    return success
                }
            }

            return false
        }

        // QQ Share
        if urlScheme.hasPrefix("QQ") {
            guard let errorDescription = url.monkeyking_queryDictionary["error"] else { return false }
            let success = (errorDescription == "0")
            if success {
                shared.deliverCompletionHandler?(.success(nil))
            } else {
                let error: Error = errorDescription == "-4"
                    ? .userCancelled
                    : .sdk(.other(code: errorDescription))
                shared.deliverCompletionHandler?(.failure(error))
            }
            return success
        }

        // QQ OAuth
        if urlScheme.hasPrefix("tencent") {
            guard let account = shared.accountSet[.qq] else { return false }
            guard
                let data = UIPasteboard.general.data(forPasteboardType: "com.tencent.tencent\(account.appID)"),
                let info = NSKeyedUnarchiver.unarchiveObject(with: data) as? [String: Any] else {
                shared.oauthCompletionHandler?(.failure(.sdk(.deserializeFailed)))
                return false
            }
            guard let result = info["ret"] as? Int, result == 0 else {
                let error: Error
                if let errorDomatin = info["user_cancelled"] as? String, errorDomatin == "YES" {
                    error = .userCancelled
                } else {
                    error = .apiRequest(.unrecognizedError(response: nil))
                }
                shared.oauthCompletionHandler?(.failure(error))
                return false
            }

            shared.oauthCompletionHandler?(.success(info))
            return true
        }

        // Weibo
        if urlScheme.hasPrefix("wb") {
            let items = UIPasteboard.general.items
            var results = [String: Any]()
            for item in items {
                for (key, value) in item {
                    if let valueData = value as? Data, key == "transferObject" {
                        results[key] = NSKeyedUnarchiver.unarchiveObject(with: valueData)
                    }
                }
            }
            guard
                let responseInfo = results["transferObject"] as? [String: Any],
                let type = responseInfo["__class"] as? String else {
                return false
            }
            guard let statusCode = responseInfo["statusCode"] as? Int else {
                return false
            }
            switch type {
            // OAuth
            case "WBAuthorizeResponse":
                if statusCode != 0 {
                    shared.oauthCompletionHandler?(.failure(.apiRequest(.unrecognizedError(response: responseInfo))))
                    return false
                }

                shared.oauthCompletionHandler?(.success(responseInfo))
                return true
            // Share
            case "WBSendMessageToWeiboResponse":
                let success = (statusCode == 0)
                if success {
                    shared.deliverCompletionHandler?(.success(nil))
                } else {
                    let error: Error = statusCode == -1
                        ? .userCancelled
                        : .sdk(.other(code: String(statusCode)))
                    shared.deliverCompletionHandler?(.failure(error))
                }
                return success
            default:
                break
            }
        }

        // Pocket OAuth
        if urlScheme.hasPrefix("pocketapp") {
            shared.oauthCompletionHandler?(.success(nil))
            return true
        }

        // Alipay
        let account = shared.accountSet[.alipay]
        if let appID = account?.appID, urlScheme == "ap" + appID || urlScheme == "apoauth" + appID {
            let urlString = url.absoluteString
            if urlString.contains("//safepay/?") {

                guard
                    let query = url.query,
                    let response = query.monkeyking_urlDecodedString?.data(using: .utf8),
                    let json = response.monkeyking_json,
                    let memo = json["memo"] as? [String: Any],
                    let status = memo["ResultStatus"] as? String
                else {
                    shared.oauthCompletionHandler?(.failure(.apiRequest(.missingParameter)))
                    shared.payCompletionHandler?(.failure(.apiRequest(.missingParameter)))
                    return false
                }

                if status != "9000" {
                    shared.oauthCompletionHandler?(.failure(.apiRequest(.invalidParameter)))
                    shared.payCompletionHandler?(.failure(.apiRequest(.invalidParameter)))
                    return false
                }

                if urlScheme == "apoauth" + appID { // OAuth
                    let resultStr = memo["result"] as? String ?? ""
                    let urlStr = "https://www.example.com?" + resultStr
                    let resultDic = URL(string: urlStr)?.monkeyking_queryDictionary ?? [:]
                    if let _ = resultDic["auth_code"], let _ = resultDic["scope"] {
                        shared.oauthCompletionHandler?(.success(resultDic))
                        return true
                    }
                    shared.oauthCompletionHandler?(.failure(.apiRequest(.unrecognizedError(response: resultDic))))
                    return false
                } else { // Pay
                    shared.payCompletionHandler?(.success(()))
                }
                return true
            } else { // Share
                guard
                    let data = UIPasteboard.general.data(forPasteboardType: "com.alipay.openapi.pb.resp.\(appID)"),
                    let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
                    let objects = dict["$objects"] as? NSArray,
                    let result = objects[12] as? Int else {
                    return false
                }
                let success = (result == 0)
                if success {
                    shared.deliverCompletionHandler?(.success(nil))
                } else {
                    shared.deliverCompletionHandler?(.failure(.sdk(.other(code: String(result))))) // TODO: user cancelled
                }
                return success
            }
        }

        if let handler = shared.openSchemeCompletionHandler {
            handler(.success(url))
            return true
        }

        return false
    }
}
