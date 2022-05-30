
import UIKit

extension MonkeyKing {

    public class func oauth(for platform: SupportedPlatform, scope: String? = nil, requestToken: String? = nil, dataString: String? = nil, completionHandler: @escaping OAuthCompletionHandler) {
        guard platform.isAppInstalled || platform.canWebOAuth else {
            completionHandler(.failure(.noApp))
            return
        }
        guard let account = shared.accountSet[platform] else {
            completionHandler(.failure(.noAccount))
            return
        }

        shared.oauthCompletionHandler = completionHandler
        shared.payCompletionHandler = nil
        shared.deliverCompletionHandler = nil
        shared.openSchemeCompletionHandler = nil

        switch account {
        case .alipay(let appID):

            guard let dataStr = dataString else {
                completionHandler(.failure(.apiRequest(.missingParameter)))
                return
            }

            let appUrlScheme = "apoauth" + appID
            let resultDic: [String: String] = ["fromAppUrlScheme": appUrlScheme, "requestType": "SafePay", "dataString": dataStr]

            guard var resultStr = resultDic.toString else {
                completionHandler(.failure(.sdk(.urlEncodeFailed)))
                return
            }

            resultStr = resultStr.replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: " ", with: "")
            resultStr = resultStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? resultStr
            resultStr = "alipay://alipayclient/?" + resultStr

            guard let url = URL(string: resultStr) else {
                completionHandler(.failure(.sdk(.urlEncodeFailed)))
                return
            }

            shared.openURL(url) { flag in
                if flag { return }
                completionHandler(.failure(.sdk(.invalidURLScheme)))
            }

        case .weChat(let appID, _, _, let universalLink):
            let scope = scope ?? "snsapi_userinfo"

            if !platform.isAppInstalled {
                // SMS OAuth
                // uid??
                let accessTokenAPI = "https://open.weixin.qq.com/connect/mobilecheck?appid=\(appID)&uid=1926559385"
                addWebView(withURLString: accessTokenAPI)
            } else {
                var urlComponents: URLComponents?
                var wxUrlOptions = [UIApplication.OpenExternalURLOptionsKey : Any]()
                
                let schemeURLComponents: ()-> URLComponents? = {
                    var urlComponents = URLComponents(string: "weixin://app/\(appID)/auth/")
                    urlComponents?.queryItems = [
                        URLQueryItem(name: "scope", value: scope),
                        URLQueryItem(name: "state", value: "Weixinauth"),
                    ]
                    return urlComponents
                }

                if let universalLink = universalLink,
                   let authUrl = shared.wechatUniversalLink(of: "auth") {
                    urlComponents = URLComponents(url: authUrl, resolvingAgainstBaseURL: true)
                    urlComponents?.queryItems?.append(contentsOf: [
                        URLQueryItem(name: "scope", value: scope),
                        URLQueryItem(name: "state", value: "Weixinauth"), // Weixinauth instead?
                    ])

                    shared.setPasteboard(of: appID, with: [
                        "universalLink": universalLink,
                        "isAuthResend": false,
                        "command": "0"
                    ])

                    wxUrlOptions[.universalLinksOnly] = true
                } else {
                    urlComponents = schemeURLComponents()
                }
                
                handleWeChatAuth(
                    urlComponents,
                    schemeURLComponents(),
                    wxUrlOptions,
                    completionHandler: completionHandler)
            }
        case .qq(let appID, _):
            let scope = scope ?? ""
            guard !platform.isAppInstalled else {
                let appName = Bundle.main.monkeyking_displayName ?? "nixApp"
                let dic: [String: Any] = [
                    "app_id": appID,
                    "app_name": appName,
                    "client_id": appID,
                    "response_type": "token",
                    "scope": scope,
                    "sdkp": "i",
                    "sdkv": "3.3.9_lite",
                    "status_machine": UIDevice.current.model,
                    "status_os": UIDevice.current.systemVersion,
                    "status_version": UIDevice.current.systemVersion,
                ]
                let data = NSKeyedArchiver.archivedData(withRootObject: dic)
                UIPasteboard.general.setData(data, forPasteboardType: "com.tencent.tencent\(appID)")

                var urlComponents = URLComponents(string: "mqqOpensdkSSoLogin://SSoLogin/tencent\(appID)/com.tencent.tencent\(appID)")
                urlComponents?.queryItems = [
                    URLQueryItem(name: "generalpastboard", value: "1"),
                ]

                guard let url = urlComponents?.url else {
                    completionHandler(.failure(.sdk(.urlEncodeFailed)))
                    return
                }

                shared.openURL(url) { flag in
                    if flag { return }
                    completionHandler(.failure(.sdk(.invalidURLScheme)))
                }
                return
            }
            // Web OAuth
            let accessTokenAPI = "https://xui.ptlogin2.qq.com/cgi-bin/xlogin?appid=716027609&pt_3rd_aid=209656&style=35&s_url=http%3A%2F%2Fconnect.qq.com&refer_cgi=m_authorize&client_id=\(appID)&redirect_uri=auth%3A%2F%2Fwww.qq.com&response_type=token&scope=\(scope)"
            addWebView(withURLString: accessTokenAPI)
        case .weibo(let appID, _, let redirectURL, _):
            let scope = scope ?? "all"
            guard !platform.isAppInstalled else {
                let uuidString = UUID().uuidString
                let transferObjectData = NSKeyedArchiver.archivedData(
                    withRootObject: [
                        "__class": "WBAuthorizeRequest",
                        "redirectURI": redirectURL,
                        "requestID": uuidString,
                        "scope": scope,
                    ]
                )
                let userInfoData = NSKeyedArchiver.archivedData(
                    withRootObject: [
                        "mykey": "as you like",
                        "SSO_From": "SendMessageToWeiboViewController",
                    ]
                )
                let appData = NSKeyedArchiver.archivedData(
                    withRootObject: [
                        "appKey": appID,
                        "bundleID": Bundle.main.monkeyking_bundleID ?? "",
                        "name": Bundle.main.monkeyking_displayName ?? "",
                        "universalLink": account.universalLink ?? "",
                    ]
                )
                let authItems: [[String: Any]] = [
                    ["transferObject": transferObjectData],
                    ["userInfo": userInfoData],
                    ["app": appData],
                ]
                UIPasteboard.general.items = authItems

                guard let url = weiboSchemeLink(uuidString: uuidString) else {
                    completionHandler(.failure(.sdk(.urlEncodeFailed)))
                    return
                }

                if account.universalLink != nil,
                   #available(iOS 10.0, *),
                   let ulURL = weiboUniversalLink(query: url.query) {
                        shared.openURL(ulURL, options: [.universalLinksOnly: true]) { succeed in
                            if !succeed {
                                fallbackToScheme(url: url, completionHandler: completionHandler)
                            }
                        }
                } else {
                    fallbackToScheme(url: url, completionHandler: completionHandler)
                }

                return
            }
            // Web OAuth
            let accessTokenAPI = "https://api.weibo.com/oauth2/authorize?client_id=\(appID)&response_type=code&redirect_uri=\(redirectURL)&scope=\(scope)"
            addWebView(withURLString: accessTokenAPI)
        case .pocket(let appID):
            guard let startIndex = appID.range(of: "-")?.lowerBound else {
                return
            }
            let prefix = appID[..<startIndex]
            let redirectURLString = "pocketapp\(prefix):authorizationFinished"
            guard let requestToken = requestToken else { return }
            guard !platform.isAppInstalled else {
                var urlComponents = URLComponents(string: "pocket-oauth-v1:///authorize")
                urlComponents?.queryItems = [
                    URLQueryItem(name: "request_token", value: requestToken),
                    URLQueryItem(name: "redirect_uri", value: redirectURLString),
                ]

                guard let url = urlComponents?.url else {
                    completionHandler(.failure(.sdk(.urlEncodeFailed)))
                    return
                }

                shared.openURL(url) { flag in
                    if flag { return }
                    completionHandler(.failure(.sdk(.invalidURLScheme)))
                }
                return
            }
            let requestTokenAPI = "https://getpocket.com/auth/authorize?request_token=\(requestToken)&redirect_uri=\(redirectURLString)"
            DispatchQueue.main.async {
                addWebView(withURLString: requestTokenAPI)
            }
        case .twitter(let appID, let appKey, let redirectURL):
            shared.twitterAuthenticate(appID: appID, appKey: appKey, redirectURL: redirectURL)
        }
    }
    
    private class func handleWeChatAuth(
        _ urlComponents: URLComponents?,
        _ default: URLComponents?,
        _ wxUrlOptions: [UIApplication.OpenExternalURLOptionsKey : Any],
        completionHandler: @escaping OAuthCompletionHandler) {
        guard let url = urlComponents?.url else {
            completionHandler(.failure(.sdk(.urlEncodeFailed)))
            return
        }
        shared.openURL(url, options: wxUrlOptions) { flag in
            if flag { return }
            if wxUrlOptions.isEmpty {
                completionHandler(.failure(.sdk(.invalidURLScheme)))
                return
            }
            handleWeChatAuth(`default`, nil, [:], completionHandler: completionHandler)
        }
    }

    private class func fallbackToScheme(url: URL, completionHandler: @escaping OAuthCompletionHandler) {
        shared.openURL(url) { succeed in
            if succeed {
                return
            }
            completionHandler(.failure(.sdk(.invalidURLScheme)))
        }
    }

    public class func weChatOAuthForCode(scope: String? = nil,
                                         state: String? = nil,
                                         completionHandler: @escaping OAuthFromWeChatCodeCompletionHandler) {
        let platform = SupportedPlatform.weChat

        guard platform.isAppInstalled || platform.canWebOAuth else {
            completionHandler(.failure(.noApp))
            return
        }
        guard let account = shared.accountSet[platform] else {
            completionHandler(.failure(.noAccount))
            return
        }

        shared.oauthFromWeChatCodeCompletionHandler = completionHandler

        if case .weChat(let appID, _, _, let universalLink) = account {
            let scope = scope ?? "snsapi_userinfo"
            let state = state ?? "Weixinauth"

            let items = [
                URLQueryItem(name: "scope", value: scope),
                URLQueryItem(name: "state", value: state),
            ]

            guard let url = shared.wechatUniversalLink(of: "auth", items: items),
                  let universalLink = universalLink else {
                completionHandler(.failure(.sdk(.urlEncodeFailed)))
                return
            }

            shared.setPasteboard(of: appID, with: [
                "universalLink": universalLink,
                "isAuthResend": false,
                "command": "0"
            ])

            shared.openURL(url) { flag in
                if flag { return }
                completionHandler(.failure(.sdk(.invalidURLScheme)))
            }
        }
    }

    // Twitter Authenticate
    // https://dev.twitter.com/web/sign-in/implementing
    private func twitterAuthenticate(appID: String, appKey: String, redirectURL: String) {
        let requestTokenAPI = "https://api.twitter.com/oauth/request_token"
        let oauthString = Networking.shared.authorizationHeader(for: .post, urlString: requestTokenAPI, appID: appID, appKey: appKey, accessToken: nil, accessTokenSecret: nil, parameters: ["oauth_callback": redirectURL], isMediaUpload: false)
        let oauthHeader = ["Authorization": oauthString]
        Networking.shared.request(requestTokenAPI, method: .post, parameters: nil, encoding: .url, headers: oauthHeader) { responseData, _, _ in
            if let responseData = responseData,
                let requestToken = (responseData["oauth_token"] as? String) {
                let loginURL = "https://api.twitter.com/oauth/authenticate?oauth_token=\(requestToken)"
                MonkeyKing.addWebView(withURLString: loginURL)
            }
        }
    }
}
