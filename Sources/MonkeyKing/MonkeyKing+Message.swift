
import UIKit

extension MonkeyKing {

    public enum MiniAppType: Int {
        case release = 0
        case test = 1
        case preview = 2
    }

    public enum Media {
        case url(URL)
        case image(UIImage)
        case imageData(Data)
        case gif(Data)
        case audio(audioURL: URL, linkURL: URL?)
        case video(URL)
        case file(Data, fileExt: String?) /// file extension for wechat file share
        case miniApp(url: URL, path: String, withShareTicket: Bool, type: MiniAppType)
    }

    public typealias Info = (title: String?, description: String?, thumbnail: UIImage?, media: Media?)

    public enum Message {

        public enum WeChatSubtype {
            case session(info: Info)
            case timeline(info: Info)
            case favorite(info: Info)

            var scene: String {
                switch self {
                case .session:
                    return "0"
                case .timeline:
                    return "1"
                case .favorite:
                    return "2"
                }
            }

            var info: Info {
                switch self {
                case .session(let info):
                    return info
                case .timeline(let info):
                    return info
                case .favorite(let info):
                    return info
                }
            }
        }

        case weChat(WeChatSubtype)

        public enum QQSubtype {
            case friends(info: Info)
            case zone(info: Info)
            case favorites(info: Info)
            case dataline(info: Info)

            var scene: Int {
                switch self {
                case .friends:
                    return 0x00
                case .zone:
                    return 0x01
                case .favorites:
                    return 0x08
                case .dataline:
                    return 0x10
                }
            }

            var info: Info {
                switch self {
                case .friends(let info):
                    return info
                case .zone(let info):
                    return info
                case .favorites(let info):
                    return info
                case .dataline(let info):
                    return info
                }
            }
        }

        case qq(QQSubtype)

        public enum WeiboSubtype {
            case `default`(info: Info, accessToken: String?)

            var info: Info {
                switch self {
                case .default(let info, _):
                    return info
                }
            }

            var accessToken: String? {
                switch self {
                case .default(_, let accessToken):
                    return accessToken
                }
            }
        }

        case weibo(WeiboSubtype)

        public enum AlipaySubtype {
            case friends(info: Info)
            case timeline(info: Info)

            var scene: NSNumber {
                switch self {
                case .friends:
                    return 0
                case .timeline:
                    return 1
                }
            }

            var info: Info {
                switch self {
                case .friends(let info):
                    return info
                case .timeline(let info):
                    return info
                }
            }
        }

        case alipay(AlipaySubtype)

        public enum TwitterSubtype {
            case `default`(info: Info, mediaIDs: [String]?, accessToken: String?, accessTokenSecret: String?)

            var info: Info {
                switch self {
                case .default(let info, _, _, _):
                    return info
                }
            }

            var mediaIDs: [String]? {
                switch self {
                case .default(_, let mediaIDs, _, _):
                    return mediaIDs
                }
            }

            var accessToken: String? {
                switch self {
                case .default(_, _, let accessToken, _):
                    return accessToken
                }
            }

            var accessTokenSecret: String? {
                switch self {
                case .default(_, _, _, let accessTokenSecret):
                    return accessTokenSecret
                }
            }
        }

        case twitter(TwitterSubtype)

        public var canBeDelivered: Bool {
            switch platform {
            case .weibo, .twitter:
                return true
            default:
                return platform.isAppInstalled
            }
        }
    }

    private class func fallbackToScheme(url: URL, completionHandler: @escaping DeliverCompletionHandler) {
        shared.openURL(url) { succeed in
            if succeed {
                return
            }
            completionHandler(.failure(.sdk(.invalidURLScheme)))
        }
    }

    public class func deliver(_ message: Message, completionHandler: @escaping DeliverCompletionHandler) {
        guard message.canBeDelivered else {
            completionHandler(.failure(.noApp))
            return
        }
        guard let account = shared.accountSet[message.platform] else {
            completionHandler(.failure(.noAccount))
            return
        }

        shared.deliverCompletionHandler = completionHandler
        shared.payCompletionHandler = nil
        shared.oauthCompletionHandler = nil
        shared.openSchemeCompletionHandler = nil

        let appID = account.appID
        switch message {
        case .weChat(let type):
            var weChatMessageInfo: [String: Any] = [
                "scene": type.scene,
                "command": "1010",
            ]
            let info = type.info
            if let title = info.title {
                weChatMessageInfo["title"] = title
            }
            if let description = info.description {
                weChatMessageInfo["description"] = description
            }
            if let thumbnailImage = info.thumbnail {
                weChatMessageInfo["thumbData"] = thumbnailImage.monkeyking_compressedImageData
            }
            if let media = info.media {
                switch media {
                case .url(let url):
                    weChatMessageInfo["objectType"] = "5"
                    weChatMessageInfo["mediaUrl"] = url.absoluteString
                case .image(let image):
                    weChatMessageInfo["objectType"] = "2"
                    if let imageData = image.jpegData(compressionQuality: 0.9) {
                        weChatMessageInfo["fileData"] = imageData
                    }
                case .imageData(let imageData):
                    weChatMessageInfo["objectType"] = "2"
                    weChatMessageInfo["fileData"] = imageData
                case .gif(let data):
                    weChatMessageInfo["objectType"] = "8"
                    weChatMessageInfo["fileData"] = data
                case .audio(let audioURL, let linkURL):
                    weChatMessageInfo["objectType"] = "3"
                    if let urlString = linkURL?.absoluteString {
                        weChatMessageInfo["mediaUrl"] = urlString
                    }
                    weChatMessageInfo["mediaDataUrl"] = audioURL.absoluteString
                case .video(let url):
                    weChatMessageInfo["objectType"] = "4"
                    weChatMessageInfo["mediaUrl"] = url.absoluteString
                case .miniApp(let url, let path, let withShareTicket, let type):
                    if case .weChat(_, _, let miniProgramID, let universalLink) = account {
                        weChatMessageInfo["objectType"] = "36"
                        if let hdThumbnailImage = info.thumbnail {
                            weChatMessageInfo["hdThumbData"] = hdThumbnailImage.monkeyking_resetSizeOfImageData(maxSize: 127 * 1024)
                        }
                        weChatMessageInfo["mediaUrl"] = url.absoluteString
                        weChatMessageInfo["appBrandPath"] = path
                        weChatMessageInfo["withShareTicket"] = withShareTicket
                        weChatMessageInfo["miniprogramType"] = type.rawValue
                        weChatMessageInfo["universalLink"] = universalLink
                        if let miniProgramID = miniProgramID {
                            weChatMessageInfo["appBrandUserName"] = miniProgramID
                        } else {
                            fatalError("Missing `miniProgramID`!")
                        }
                    }
                case .file(let fileData, let fileExt):
                    weChatMessageInfo["objectType"] = "6"
                    weChatMessageInfo["fileData"] = fileData
                    weChatMessageInfo["fileExt"] = fileExt

                    if let fileExt = fileExt, let title = info.title {
                        let suffix = ".\(fileExt)"
                        weChatMessageInfo["title"] = title.hasSuffix(suffix) ? title : title + suffix
                    }
                }
            } else { // Text Share
                weChatMessageInfo["command"] = "1020"
            }

            lastMessage = message
            shared.setPasteboard(of: appID, with: weChatMessageInfo)

            if
                let commandUniversalLink = shared.wechatUniversalLink(of: "sendreq"), #available(iOS 10.0, *),
                let universalLink = MonkeyKing.shared.accountSet[.weChat]?.universalLink,
                let ulURL = URL(string: commandUniversalLink)
            {
                weChatMessageInfo["universalLink"] = universalLink
                weChatMessageInfo["isAutoResend"] = false

                shared.openURL(ulURL, options: [.universalLinksOnly: true]) { succeed in
                    if !succeed, let schemeURL = URL(string: "weixin://app/\(appID)/sendreq/?") {
                        fallbackToScheme(url: schemeURL, completionHandler: completionHandler)
                    }
                }
            } else if let schemeURL = URL(string: "weixin://app/\(appID)/sendreq/?") {
                fallbackToScheme(url: schemeURL, completionHandler: completionHandler)
            }

        case .qq(let type):
            let callbackName = appID.monkeyking_qqCallbackName
            var qqSchemeURLString = "mqqapi://share/to_fri?"
            if let encodedAppDisplayName = Bundle.main.monkeyking_displayName?.monkeyking_base64EncodedString {
                qqSchemeURLString += "thirdAppDisplayName=" + encodedAppDisplayName
            } else {
                qqSchemeURLString += "thirdAppDisplayName=" + "nixApp" // Should not be there
            }
            qqSchemeURLString += "&version=1&cflag=\(type.scene)"
            qqSchemeURLString += "&callback_type=scheme&generalpastboard=1"
            qqSchemeURLString += "&callback_name=\(callbackName)"
            qqSchemeURLString += "&src_type=app&shareType=0&file_type="
            if let media = type.info.media {
                func handleNews(with url: URL, mediaType: String?) {
                    if let thumbnailData = type.info.thumbnail?.monkeyking_compressedImageData {
                        var dic: [String: Any] = ["previewimagedata": thumbnailData]
                        if let oldText = UIPasteboard.general.oldText {
                            dic["pasted_string"] = oldText
                        }
                        let data = NSKeyedArchiver.archivedData(withRootObject: dic)
                        UIPasteboard.general.setData(data, forPasteboardType: "com.tencent.mqq.api.apiLargeData")
                    }
                    qqSchemeURLString += mediaType ?? "news"
                    guard let encodedURLString = url.absoluteString.monkeyking_base64AndURLEncodedString else {
                        completionHandler(.failure(.sdk(.urlEncodeFailed)))
                        return
                    }
                    qqSchemeURLString += "&url=\(encodedURLString)"
                }
                switch media {
                case .url(let url):
                    handleNews(with: url, mediaType: "news")
                case .image(let image):
                    guard let imageData = image.jpegData(compressionQuality: 0.9) else {
                        completionHandler(.failure(.resource(.invalidImageData)))
                        return
                    }
                    var dic: [String: Any] = ["file_data": imageData]
                    if let thumbnail = type.info.thumbnail, let thumbnailData = thumbnail.jpegData(compressionQuality: 0.9) {
                        dic["previewimagedata"] = thumbnailData
                    }
                    // TODO: handle previewimageUrl string aswell

                    if let oldText = UIPasteboard.general.oldText {
                        dic["pasted_string"] = oldText
                    }
                    let data = NSKeyedArchiver.archivedData(withRootObject: dic)
                    UIPasteboard.general.setData(data, forPasteboardType: "com.tencent.mqq.api.apiLargeData")
                    qqSchemeURLString += "img"
                case .imageData(let data), .gif(let data):
                    var dic: [String: Any] = ["file_data": data]
                    if let thumbnail = type.info.thumbnail, let thumbnailData = thumbnail.jpegData(compressionQuality: 0.9) {
                        dic["previewimagedata"] = thumbnailData
                    }
                    if let oldText = UIPasteboard.general.oldText {
                        dic["pasted_string"] = oldText
                    }
                    let archivedData = NSKeyedArchiver.archivedData(withRootObject: dic)
                    UIPasteboard.general.setData(archivedData, forPasteboardType: "com.tencent.mqq.api.apiLargeData")
                    qqSchemeURLString += "img"
                case .audio(let audioURL, _):
                    handleNews(with: audioURL, mediaType: "audio")
                case .video(let url):
                    handleNews(with: url, mediaType: nil) // No video type, default is news type.
                case .file(let fileData, _):
                    var dic: [String: Any] = ["file_data": fileData]
                    if let oldText = UIPasteboard.general.oldText {
                        dic["pasted_string"] = oldText
                    }
                    let data = NSKeyedArchiver.archivedData(withRootObject: dic)
                    UIPasteboard.general.setData(data, forPasteboardType: "com.tencent.mqq.api.apiLargeData")
                    qqSchemeURLString += "localFile"
                    if let filename = type.info.description?.monkeyking_urlEncodedString {
                        qqSchemeURLString += "&fileName=\(filename)"
                    }
                case .miniApp:
                    fatalError("QQ not supports Mini App type")
                }
                if let encodedTitle = type.info.title?.monkeyking_base64AndURLEncodedString {
                    qqSchemeURLString += "&title=\(encodedTitle)"
                }
                if let encodedDescription = type.info.description?.monkeyking_base64AndURLEncodedString {
                    qqSchemeURLString += "&objectlocation=pasteboard&description=\(encodedDescription)"
                }
                qqSchemeURLString += "&sdkv=3.3.9_lite"

            } else { // Share Text
                // fix #75
                switch type {
                case .zone:
                    qqSchemeURLString += "qzone&title="
                default:
                    qqSchemeURLString += "text&file_data="
                }
                if let encodedDescription = type.info.description?.monkeyking_base64AndURLEncodedString {
                    qqSchemeURLString += "\(encodedDescription)"
                }
            }

            guard let comps = URLComponents(string: qqSchemeURLString), let url = comps.url else {
                completionHandler(.failure(.sdk(.urlEncodeFailed)))
                return
            }

            lastMessage = message

            if account.universalLink != nil, var ulComps = URLComponents(string: "https://qm.qq.com/opensdkul/mqqapi/share/to_fri") {
                ulComps.query = comps.query

                if let token = qqAppSignToken {
                    ulComps.queryItems?.append(.init(name: "appsign_token", value: token))
                }
                if let txid = qqAppSignTxid {
                    ulComps.queryItems?.append(.init(name: "appsign_txid", value: txid))
                }
                if let ulURL = ulComps.url, #available(iOS 10.0, *) {
                    shared.openURL(ulURL, options: [.universalLinksOnly: true]) { succeed in
                        if !succeed {
                            fallbackToScheme(url: url, completionHandler: completionHandler)
                        }
                    }
                }
            } else {
                fallbackToScheme(url: url, completionHandler: completionHandler)
            }

        case .weibo(let type):
            guard !shared.canOpenURL(URL(string: "weibosdk://request")!) else {
                // App Share
                var messageInfo: [String: Any] = [
                    "__class": "WBMessageObject",
                ]
                let info = type.info
                if let description = info.description {
                    messageInfo["text"] = description
                }
                if let media = info.media {
                    switch media {
                    case .url(let url):
                        if let thumbnailData = info.thumbnail?.monkeyking_compressedImageData {
                            var mediaObject: [String: Any] = [
                                "__class": "WBWebpageObject",
                                "objectID": "identifier1",
                            ]
                            mediaObject["webpageUrl"] = url.absoluteString
                            mediaObject["title"] = info.title ?? ""
                            mediaObject["thumbnailData"] = thumbnailData
                            messageInfo["mediaObject"] = mediaObject
                        } else {
                            // Deliver text directly.
                            let text = info.description ?? ""
                            messageInfo["text"] = text.isEmpty ? url.absoluteString : text + " " + url.absoluteString
                        }
                    case .image(let image):
                        if let imageData = image.jpegData(compressionQuality: 0.9) {
                            messageInfo["imageObject"] = ["imageData": imageData]
                        }
                    case .imageData(let imageData):
                        messageInfo["imageObject"] = ["imageData": imageData]
                    case .gif:
                        fatalError("Weibo not supports GIF type")
                    case .audio:
                        fatalError("Weibo not supports Audio type")
                    case .video:
                        fatalError("Weibo not supports Video type")
                    case .file:
                        fatalError("Weibo not supports File type")
                    case .miniApp:
                        fatalError("Weibo not supports Mini App type")
                    }
                }
                let uuidString = UUID().uuidString
                let dict: [String: Any] = [
                    "__class": "WBSendMessageToWeiboRequest",
                    "message": messageInfo,
                    "requestID": uuidString,
                ]
                let appData = NSKeyedArchiver.archivedData(
                    withRootObject: [
                        "appKey": appID,
                        "bundleID": Bundle.main.monkeyking_bundleID ?? "",
                        "universalLink": account.universalLink ?? ""
                    ]
                )
                let messageData: [[String: Any]] = [
                    ["transferObject": NSKeyedArchiver.archivedData(withRootObject: dict)],
                    ["app": appData],
                ]
                UIPasteboard.general.items = messageData

                var urlComponents = URLComponents(string: "weibosdk://request")
                urlComponents?.queryItems = [
                    URLQueryItem(name: "id", value: uuidString),
                    URLQueryItem(name: "sdkversion", value: "003233000"),
                    URLQueryItem(name: "luicode", value: "10000360"),
                    URLQueryItem(name: "lfid", value: Bundle.main.monkeyking_bundleID ?? ""),
                    URLQueryItem(name: "newVersion", value: "3.3"),
                ]

                guard let url = urlComponents?.url else {
                    completionHandler(.failure(.sdk(.urlEncodeFailed)))
                    return
                }

                if account.universalLink != nil, var ulComps = URLComponents(string: "https://open.weibo.com/weibosdk/request") {
                    ulComps.query = urlComponents?.query

                    ulComps.queryItems?.append(
                        URLQueryItem(name: "objId", value: uuidString)
                    )

                    if let ulURL = ulComps.url, #available(iOS 10.0, *) {
                        shared.openURL(ulURL, options: [.universalLinksOnly: true]) { succeed in
                            if !succeed {
                                fallbackToScheme(url: url, completionHandler: completionHandler)
                            }
                        }
                    }
                } else {
                    fallbackToScheme(url: url, completionHandler: completionHandler)
                }

                return
            }
            // Weibo Web Share
            let info = type.info
            var parameters = [String: Any]()
            guard let accessToken = type.accessToken else {
                completionHandler(.failure(.noAccount))
                return
            }
            parameters["access_token"] = accessToken
            var status: [String?] = [info.title, info.description]
            var mediaType = Media.url(NSURL() as URL)
            if let media = info.media {
                switch media {
                case .url(let url):
                    status.append(url.absoluteString)
                    mediaType = Media.url(url)
                case .image(let image):
                    guard let imageData = image.jpegData(compressionQuality: 0.9) else {
                        completionHandler(.failure(.resource(.invalidImageData)))
                        return
                    }
                    parameters["pic"] = imageData
                    mediaType = Media.image(image)
                case .imageData(let imageData):
                    parameters["pic"] = imageData
                    mediaType = Media.imageData(imageData)
                case .gif:
                    fatalError("web Weibo not supports GIF type")
                case .audio:
                    fatalError("web Weibo not supports Audio type")
                case .video:
                    fatalError("web Weibo not supports Video type")
                case .file:
                    fatalError("web Weibo not supports File type")
                case .miniApp:
                    fatalError("web Weibo not supports Mini App type")
                }
            }
            let statusText = status.compactMap { $0 }.joined(separator: " ")
            parameters["status"] = statusText
            switch mediaType {
            case .url:
                let urlString = "https://api.weibo.com/2/statuses/share.json"
                shared.request(urlString, method: .post, parameters: parameters) { responseData, _, error in
                    if error != nil {
                        completionHandler(.failure(.apiRequest(.connectFailed)))
                    } else if let responseData = responseData, (responseData["idstr"] as? String) == nil {
                        completionHandler(.failure(shared.buildError(with: responseData, at: .weibo)))
                    } else {
                        completionHandler(.success(nil))
                    }
                }
            case .image, .imageData:
                let urlString = "https://api.weibo.com/2/statuses/share.json"
                shared.upload(urlString, parameters: parameters) { responseData, _, error in
                    if error != nil {
                        completionHandler(.failure(.apiRequest(.connectFailed)))
                    } else if let responseData = responseData, (responseData["idstr"] as? String) == nil {
                        completionHandler(.failure(shared.buildError(with: responseData, at: .weibo)))
                    } else {
                        completionHandler(.success(nil))
                    }
                }
            case .gif:
                fatalError("web Weibo not supports GIF type")
            case .audio:
                fatalError("web Weibo not supports Audio type")
            case .video:
                fatalError("web Weibo not supports Video type")
            case .file:
                fatalError("web Weibo not supports File type")
            case .miniApp:
                fatalError("web Weibo not supports Mini App type")
            }
        case .alipay(let type):
            let dictionary = createAlipayMessageDictionary(withScene: type.scene, info: type.info, appID: appID)
            guard let data = try? PropertyListSerialization.data(fromPropertyList: dictionary, format: .xml, options: .init()) else {
                completionHandler(.failure(.sdk(.serializeFailed)))
                return
            }
            UIPasteboard.general.setData(data, forPasteboardType: "com.alipay.openapi.pb.req.\(appID)")

            var urlComponents = URLComponents(string: "alipayshare://platformapi/shareService")
            urlComponents?.queryItems = [
                URLQueryItem(name: "action", value: "sendReq"),
                URLQueryItem(name: "shareId", value: appID),
            ]

            guard let url = urlComponents?.url else {
                completionHandler(.failure(.sdk(.urlEncodeFailed)))
                return
            }

            shared.openURL(url) { flag in
                if flag { return }
                completionHandler(.failure(.sdk(.invalidURLScheme)))
            }
        case .twitter(let type):
            // MARK: - Twitter Deliver
            guard
                let accessToken = type.accessToken,
                let accessTokenSecret = type.accessTokenSecret
            else {
                completionHandler(.failure(.noAccount))
                return
            }
            let info = type.info
            var status = [info.title, info.description]
            var parameters = [String: Any]()
            var mediaType = Media.url(NSURL() as URL)
            if let media = info.media {
                switch media {
                case .url(let url):
                    status.append(url.absoluteString)
                    mediaType = Media.url(url)
                case .image(let image):
                    guard let imageData = image.jpegData(compressionQuality: 0.9) else {
                        completionHandler(.failure(.resource(.invalidImageData)))
                        return
                    }
                    parameters["media"] = imageData
                    mediaType = Media.image(image)
                case .imageData(let imageData):
                    parameters["media"] = imageData
                    mediaType = Media.imageData(imageData)
                default:
                    fatalError("web Twitter not supports this type")
                }
            }
            switch mediaType {
            case .url:
                let statusText = status.compactMap { $0 }.joined(separator: " ")
                let updateStatusAPI = "https://api.twitter.com/1.1/statuses/update.json"
                var parameters = ["status": statusText]
                if let mediaIDs = type.mediaIDs {
                    parameters["media_ids"] = mediaIDs.joined(separator: ",")
                }
                if case .twitter(let appID, let appKey, _) = account {
                    let oauthString = Networking.shared.authorizationHeader(for: .post, urlString: updateStatusAPI, appID: appID, appKey: appKey, accessToken: accessToken, accessTokenSecret: accessTokenSecret, parameters: parameters, isMediaUpload: true)
                    let headers = ["Authorization": oauthString]
                    // ref: https://dev.twitter.com/rest/reference/post/statuses/update
                    let urlString = "\(updateStatusAPI)?\(parameters.urlEncodedQueryString(using: .utf8))"
                    shared.request(urlString, method: .post, parameters: nil, headers: headers) { responseData, URLResponse, error in
                        if error != nil {
                            completionHandler(.failure(.apiRequest(.connectFailed)))
                        } else {
                            if let HTTPResponse = URLResponse as? HTTPURLResponse,
                                HTTPResponse.statusCode == 200 {
                                completionHandler(.success(nil))
                                return
                            }
                            if let responseData = responseData,
                                let _ = responseData["errors"] {
                                completionHandler(.failure(shared.buildError(with: responseData, at: .twitter)))
                                return
                            }
                            completionHandler(.failure(.apiRequest(.unrecognizedError(response: responseData))))
                        }
                    }
                }
            case .image, .imageData:
                let uploadMediaAPI = "https://upload.twitter.com/1.1/media/upload.json"
                if case .twitter(let appID, let appKey, _) = account {
                    // ref: https://dev.twitter.com/rest/media/uploading-media#keepinmind
                    let oauthString = Networking.shared.authorizationHeader(for: .post, urlString: uploadMediaAPI, appID: appID, appKey: appKey, accessToken: accessToken, accessTokenSecret: accessTokenSecret, parameters: nil, isMediaUpload: false)
                    let headers = ["Authorization": oauthString]
                    shared.upload(uploadMediaAPI, parameters: parameters, headers: headers) { responseData, URLResponse, error in
                        if let statusCode = (URLResponse as? HTTPURLResponse)?.statusCode,
                            statusCode == 200 {
                            completionHandler(.success(responseData))
                            return
                        }
                        if error != nil {
                            completionHandler(.failure(.apiRequest(.connectFailed)))
                        } else {
                            completionHandler(.failure(.apiRequest(.unrecognizedError(response: responseData))))
                        }
                    }
                }
            default:
                fatalError("web Twitter not supports this mediaType")
            }
        }
    }
}
