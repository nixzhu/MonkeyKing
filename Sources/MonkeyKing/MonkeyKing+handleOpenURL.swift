
import UIKit
import Security

extension MonkeyKing {

    public class func handleOpenUserActivity(_ userActivity: NSUserActivity) -> Bool {
        guard
            userActivity.activityType == NSUserActivityTypeBrowsingWeb,
            let url = userActivity.webpageURL
        else {
            return false
        }

        var isHandled = false

        shared.accountSet.forEach { account in
            switch account {
            case .weChat(_, _, _, let wxUL):
                if let wxUL = wxUL, url.absoluteString.hasPrefix(wxUL) {
                    isHandled = handleWechatUniversalLink(url)
                }

            case .qq(_, let qqUL):
                if let qqUL = qqUL, url.absoluteString.hasPrefix(qqUL) {
                    isHandled = handleQQUniversalLink(url)
                }

            default:
                ()
            }
        }

        lastMessage = nil

        return isHandled
    }

    // MARK: - Wechat Universal Links

    @discardableResult
    private class func handleWechatUniversalLink(_ url: URL) -> Bool {
        guard let comps = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return false
        }

        // MARK: - update token
        if let authToken = comps.valueOfQueryItem("wechat_auth_token"), !authToken.isEmpty {
            wechatAuthToken = authToken
        }

        // MARK: - refreshToken
        if comps.path.hasSuffix("refreshToken") {
            if let msg = lastMessage {
                deliver(msg, completionHandler: shared.deliverCompletionHandler ?? { _ in })
            }
            return true
        }

        // MARK: - oauth
        if  comps.path.hasSuffix("oauth"), let code = comps.valueOfQueryItem("code") {
            return handleWechatOAuth(code: code)
        }

        // MARK: - pay
        if  comps.path.hasSuffix("pay"), let ret = comps.valueOfQueryItem("ret"), let retIntValue = Int(ret) {
            if retIntValue == 0 {
                shared.payCompletionHandler?(.success(()))
                return true
            } else {
                let response: [String: String] = [
                    "ret": ret,
                    "returnKey": comps.valueOfQueryItem("returnKey") ?? "",
                    "notifyStr": comps.valueOfQueryItem("notifyStr") ?? ""
                ]
                shared.payCompletionHandler?(.failure(.apiRequest(.unrecognizedError(response: response))))
                return false
            }
        }

        // TODO: handle `resendContextReqByScheme`
        // TODO: handle `jointpay`
        // TODO: handle `offlinepay`
        // TODO: handle `cardPackage`
        // TODO: handle `choosecard`
        // TODO: handle `chooseinvoice`
        // TODO: handle `openwebview`
        // TODO: handle `openbusinesswebview`
        // TODO: handle `openranklist`
        // TODO: handle `opentypewebview`

        return handleWechatCallbackResultViaPasteboard()
    }

    private class func handleWechatOAuth(code: String) -> Bool {
        if code == "authdeny" {
            shared.oauthFromWeChatCodeCompletionHandler = nil
            return false
        }

        // Login succeed
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

    private class func handleWechatCallbackResultViaPasteboard() -> Bool {
        guard
            let data = UIPasteboard.general.data(forPasteboardType: "content"),
            let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        else {
            return false
        }

        guard
            let account = shared.accountSet[.weChat],
            let info = dict[account.appID] as? [String: Any],
            let result = info["result"] as? String,
            let resultCode = Int(result)
        else {
            return false
        }

        // OAuth Failed
        if let state = info["state"] as? String, state == "Weixinauth", resultCode != 0 {
            let error: Error = resultCode == -2
                ? .userCancelled
                : .sdk(.other(code: result))
            shared.oauthCompletionHandler?(.failure(error))
            return false
        }

        let succeed = (resultCode == 0)

        // Share or Launch Mini App
        let messageExtKey = "messageExt"
        if succeed {
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

        return succeed
    }

    // MARK: - QQ Universal Links

    @discardableResult
    private class func handleQQUniversalLink(_ url: URL) -> Bool {
        guard let comps = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return false
        }

        var error: Error?

        if
            let actionInfoString = comps.queryItems?.first(where: { $0.name == "sdkactioninfo" })?.value,
            let data = Data(base64Encoded: actionInfoString),
            let actionInfo = NSKeyedUnarchiver.unarchiveObject(with: data) as? [String: Any] {

            // What for?
            // sck_action_query=appsign_bundlenull=2&source=qq&source_scheme=mqqapi&error=0&version=1
            // sdk_action_path=
            // sdk_action_scheme=tencent101******8
            // sdk_action_host=response_from_qq

            if let query = actionInfo["sdk_action_query"] as? String {
                if query.contains("error=0") {
                    error = nil
                } else if query.contains("error=-4") {
                    error = .userCancelled
                } else {
                    // TODO: handle error_description=dGhlIHVzZXIgZ2l2ZSB1cCB0aGUgY3VycmVudCBvcGVyYXRpb24=
                    error = .noAccount
                }
            }

        }

        guard handleQQCallbackResult(url: url, error: error) else {
            return false
        }

        return true
    }

    private class func handleQQCallbackResult(url: URL, error: Error?) -> Bool {
        guard let account = shared.accountSet[.qq] else { return false }

        // Share
        // Pasteboard is empty
        if
            let ul = account.universalLink,
            url.absoluteString.hasPrefix(ul),
            url.path.contains("response_from_qq") {
            let result = error.map(Result<ResponseJSON?, Error>.failure) ?? .success(nil)
            shared.deliverCompletionHandler?(result)
            return true
        }

        // OpenApi.m:131 getDictionaryFromGeneralPasteBoard
        guard
            let data = UIPasteboard.general.data(forPasteboardType: "com.tencent.tencent\(account.appID)"),
            let info = NSKeyedUnarchiver.unarchiveObject(with: data) as? [String: Any]
        else {
            shared.oauthCompletionHandler?(.failure(.sdk(.deserializeFailed)))
            return false
        }

        if url.path.contains("mqqsignapp") && url.query?.contains("generalpastboard=1") == true {

            // OpenApi.m:680 start universallink signature.
            guard
                let token = info["appsign_token"] as? String,
                let appSignRedirect = info["appsign_redirect"] as? String,
                var redirectComps = URLComponents(string: appSignRedirect)
            else {
                return false
            }

            qqAppSignToken = token
            redirectComps.queryItems?.append(.init(name: "appsign_token", value: qqAppSignToken))

            if let callbackName = redirectComps.queryItems?.first(where: { $0.name == "callback_name" })?.value {
                qqAppSignTxid = callbackName
                redirectComps.queryItems?.append(.init(name: "appsign_txid", value: qqAppSignTxid))
            }

            if let ul = account.universalLink, url.absoluteString.hasPrefix(ul) {
                redirectComps.scheme = "https"
                redirectComps.host = "qm.qq.com"
                redirectComps.path = "/opensdkul/mqqapi/share/to_fri"
            }

            // Try to open the redirect url provided above
            if let redirectUrl = redirectComps.url, UIApplication.shared.canOpenURL(redirectUrl) {
                UIApplication.shared.openURL(redirectUrl)
            }

            // Otherwise we just send last message again
            else if let msg = lastMessage {
                deliver(msg, completionHandler: shared.deliverCompletionHandler ?? { _ in })
            }

            // The dictionary also contains "appsign_retcode=25105" and "appsign_bundlenull=2"
            // We don't have to handle them yet.

            return true
        }

        // OAuth is the only leftover
        guard let result = info["ret"] as? Int, result == 0 else {
            let error: Error
            if let errorDomatin = info["user_cancelled"] as? String, errorDomatin.uppercased() == "YES" {
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

    // MARK: - OpenURL

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

                if handleWechatOAuth(code: code) {
                    return true
                }
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

            return handleWechatCallbackResultViaPasteboard()
        }

        // QQ
        if urlScheme.lowercased().hasPrefix("qq") || urlScheme.hasPrefix("tencent") {
            let errorDescription = url.monkeyking_queryDictionary["error"] ?? url.lastPathComponent

            var error: Error?

            var success = (errorDescription == "0")
            if success {
                error = nil
            } else {
                error = errorDescription == "-4"
                    ? .userCancelled
                    : .sdk(.other(code: errorDescription))
            }

            // OAuth
            if url.path.contains("mqzone") {
                success = handleQQCallbackResult(url: url, error: error)
            }
            // Share
            else {
                if let error = error {
                    shared.deliverCompletionHandler?(.failure(error))
                } else {
                    shared.deliverCompletionHandler?(.success(nil))
                }
            }
            return success
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
