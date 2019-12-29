
import Foundation

extension MonkeyKing {

    public enum Program {
        public enum WeChatSubType {
            case miniApp(username: String, path: String?, type: MiniAppType)
        }

        case weChat(WeChatSubType)
    }

    public class func launch(_ program: Program, completionHandler: @escaping LaunchCompletionHandler) {
        guard let account = shared.accountSet[.weChat] else {
            completionHandler(.failure(.noAccount))
            return
        }

        shared.launchCompletionHandler = completionHandler

        switch program {
        case .weChat(let type):
            switch type {
            case .miniApp(let username, let path, let type):
                var components = URLComponents(string: "weixin://app/\(account.appID)/jumpWxa/")
                components?.queryItems = [
                    URLQueryItem(name: "userName", value: username),
                    URLQueryItem(name: "path", value: path),
                    URLQueryItem(name: "miniProgramType", value: String(type.rawValue)),
                ]
                guard let urlString = components?.url?.absoluteString else {
                    completionHandler(.failure(.sdk(.invalidURLScheme)))
                    return
                }
                openURL(urlString: urlString) { flag in
                    if flag { return }
                    completionHandler(.failure(.sdk(.invalidURLScheme)))
                }
            }
        }
    }
}
