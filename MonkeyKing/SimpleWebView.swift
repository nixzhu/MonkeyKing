//
//  SimpleWebView.swift
//  China
//
//  Created by Shannon Wu on 11/29/15.
//  Copyright © 2015 nixWork. All rights reserved.
//

import Foundation
import WebKit

class SimpleWebView: NSObject, WKNavigationDelegate {
    weak var shareServiceProvider: ShareServiceProvider?

    func addWebViewByURLString(URLString: String, flagCode: String? = nil) {

        guard let URL = NSURL(string: URLString) else {
            return
        }

        let webView = WKWebView()
        webView.navigationDelegate = self
        webView.frame = UIScreen.mainScreen().bounds
        webView.frame.origin.y = UIScreen.mainScreen().bounds.height

        webView.loadRequest(NSURLRequest(URL: URL))
        webView.backgroundColor = UIColor(red: 247 / 255, green: 247 / 255, blue: 247 / 255, alpha: 1.0)
        webView.scrollView.frame.origin.y = 20
        webView.scrollView.backgroundColor = webView.backgroundColor

        let activityIndicatorView = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        activityIndicatorView.center = CGPoint(x: CGRectGetMidX(webView.bounds), y: CGRectGetMidY(webView.bounds) + 30)
        activityIndicatorView.activityIndicatorViewStyle = .Gray

        webView.scrollView.addSubview(activityIndicatorView)
        activityIndicatorView.startAnimating()

        UIApplication.sharedApplication().keyWindow?.addSubview(webView)
        UIView.animateWithDuration(0.32, delay: 0.0, options: .CurveEaseOut, animations: {
            webView.frame.origin.y = 0
        }, completion: nil)

        // FlagCode For Pocket
        guard let code = flagCode else {
            return
        }
        webView.layer.name = code
    }

    func webView(webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError) {

        // Pocket OAuth
        if let errorString = error.userInfo["NSErrorFailingURLStringKey"] as? String where errorString.hasSuffix(":authorizationFinished") {
            var consumerKey = ""

            if let pocketServiceProvider = shareServiceProvider as? PocketServiceProvider {
                consumerKey = pocketServiceProvider.appID
            }

            activityIndicatorViewAction(webView, stop: true)
            webView.stopLoading()

            guard let code = webView.layer.name else {
                let error = NSError(domain: "Code is nil", code: -1, userInfo: nil)
                hideWebView(webView, tuples: (nil, nil, error))
                return
            }

            let accessTokenAPI = "https://getpocket.com/v3/oauth/authorize"
            let parameters = ["consumer_key": consumerKey, "code": code]

            SimpleNetworking.sharedInstance.request(accessTokenAPI, method: .POST, parameters: parameters) {
                (dictionary, response, error) in dispatch_async(dispatch_get_main_queue()) {
                    self.hideWebView(webView, tuples: (dictionary, response, error))
                }
            }
        }
    }

    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {

        for subview in webView.scrollView.subviews {
            if let activityIndicatorView = subview as? UIActivityIndicatorView {
                activityIndicatorView.stopAnimating()
            }
        }

        let HTML = "var button = document.createElement('a'); button.setAttribute('href', 'about:blank'); button.innerHTML = '关闭'; button.setAttribute('style', 'width: calc(100% - 40px); background-color: gray;display: inline-block;height: 40px;line-height: 40px;text-align: center;color: #777777;text-decoration: none;border-radius: 3px;background: linear-gradient(180deg, white, #f1f1f1);border: 1px solid #CACACA;box-shadow: 0 2px 3px #DEDEDE, inset 0 0 0 1px white;text-shadow: 0 2px 0 white;position: absolute;bottom: 0;margin: 20px 20px 40px 20px;font-size: 18px;'); document.body.appendChild(button);  document.querySelector('aside.logins').style.display = 'none';"

        webView.evaluateJavaScript(HTML, completionHandler: nil)
    }

    func webView(webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {

        guard let URL = webView.URL else {
            webView.stopLoading()
            return
        }

        // Close Button
        if URL.absoluteString.containsString("about:blank") {
            let error = NSError(domain: "User Cancelled", code: -1, userInfo: nil)
            hideWebView(webView, tuples: (nil, nil, error))
        }

        // QQ Web OAuth
        guard URL.absoluteString.containsString("&access_token=") else {
            return
        }

        guard let fragment = URL.fragment?.characters.dropFirst(), newURL = NSURL(string: "limon.top/?\(String(fragment))") else {
            return
        }

        let components = NSURLComponents(URL: newURL, resolvingAgainstBaseURL: false)

        guard let items = components?.queryItems else {
            return
        }

        var infos = [String: AnyObject]()
        items.forEach {
            infos[$0.name] = $0.value
        }

        hideWebView(webView, tuples: (infos, nil, nil))
    }

    func webView(webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {

        guard let URL = webView.URL else {
            return
        }

        if let weiboServiceProvider = shareServiceProvider as? WeiboServiceProvier {
            if URL.absoluteString.lowercaseString.hasPrefix(weiboServiceProvider.redirectURL) {

                webView.stopLoading()

                guard let code = URL.monkeyking_queryInfo["code"] else {
                    return
                }

                var accessTokenAPI = "https://api.weibo.com/oauth2/access_token?"
                accessTokenAPI += "client_id=" + weiboServiceProvider.appID
                accessTokenAPI += "&client_secret=" + weiboServiceProvider.appKey
                accessTokenAPI += "&grant_type=authorization_code&"
                accessTokenAPI += "redirect_uri=" + weiboServiceProvider.redirectURL
                accessTokenAPI += "&code=" + code


                SimpleNetworking.sharedInstance.request(accessTokenAPI, method: .POST) {
                    (dictionary, response, error) in dispatch_async(dispatch_get_main_queue()) {
                        self.hideWebView(webView, tuples: (dictionary, response, error))
                    }
                }
            }
        }
    }

    func hideWebView(webView: WKWebView, tuples: (NSDictionary?, NSURLResponse?, NSError?)?) {

        activityIndicatorViewAction(webView, stop: true)
        webView.stopLoading()

        UIView.animateWithDuration(0.3, delay: 0.0, options: .CurveEaseOut, animations: {
            webView.frame.origin.y = UIScreen.mainScreen().bounds.height

        }, completion: {
            _ in webView.removeFromSuperview()
            self.shareServiceProvider?.oauthCompletionHandler?(tuples?.0, tuples?.1, tuples?.2)
        })
    }

    func activityIndicatorViewAction(webView: WKWebView, stop: Bool) {
        for subview in webView.scrollView.subviews {
            if let activityIndicatorView = subview as? UIActivityIndicatorView {
                guard stop else {
                    activityIndicatorView.startAnimating()
                    return
                }
                activityIndicatorView.stopAnimating()
            }
        }
    }
}