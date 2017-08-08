
import Foundation

extension Set {

    subscript(platform: MonkeyKing.SupportedPlatform) -> MonkeyKing.Account? {
        let accountSet = MonkeyKing.shared.accountSet
        switch platform {
        case .weChat:
            for account in accountSet {
                if case .weChat = account {
                    return account
                }
            }
        case .qq:
            for account in accountSet {
                if case .qq = account {
                    return account
                }
            }
        case .weibo:
            for account in accountSet {
                if case .weibo = account {
                    return account
                }
            }
        case .pocket:
            for account in accountSet {
                if case .pocket = account {
                    return account
                }
            }
        case .alipay:
            for account in accountSet {
                if case .alipay = account {
                    return account
                }
            }
        case .twitter:
            for account in accountSet {
                if case .twitter = account {
                    return account
                }
            }
        }
        return nil
    }

    subscript(platform: MonkeyKing.Message) -> MonkeyKing.Account? {
        let accountSet = MonkeyKing.shared.accountSet
        switch platform {
        case .weChat:
            for account in accountSet {
                if case .weChat = account {
                    return account
                }
            }
        case .qq:
            for account in accountSet {
                if case .qq = account {
                    return account
                }
            }
        case .weibo:
            for account in accountSet {
                if case .weibo = account {
                    return account
                }
            }
        case .alipay:
            for account in accountSet {
                if case .alipay = account {
                    return account
                }
            }
        case .twitter:
            for account in accountSet {
                if case .twitter = account {
                    return account
                }
            }
        }
        return nil
    }
}

extension Bundle {

    var monkeyking_displayName: String? {
        func getNameByInfo(_ info: [String : Any]) -> String? {
            guard let displayName = info["CFBundleDisplayName"] as? String else {
                return info["CFBundleName"] as? String
            }
            return displayName
        }
        var info = infoDictionary
        if let localizedInfo = localizedInfoDictionary, !localizedInfo.isEmpty {
            for (key, value) in localizedInfo {
                info?[key] = value
            }
        }
        guard let unwrappedInfo = info else {
            return nil
        }
        return getNameByInfo(unwrappedInfo)
    }

    var monkeyking_bundleID: String? {
        return object(forInfoDictionaryKey: "CFBundleIdentifier") as? String
    }
}

extension String {

    var monkeyking_base64EncodedString: String? {
        return data(using: .utf8)?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
    }

    var monkeyking_urlEncodedString: String? {
        return addingPercentEncoding(withAllowedCharacters: CharacterSet.urlHostAllowed)
    }

    var monkeyking_base64AndURLEncodedString: String? {
        return monkeyking_base64EncodedString?.monkeyking_urlEncodedString
    }

    var monkeyking_urlDecodedString: String? {
        return replacingOccurrences(of: "+", with: " ").removingPercentEncoding
    }

    var monkeyking_qqCallbackName: String {
        var hexString = String(format: "%02llx", (self as NSString).longLongValue)
        while hexString.characters.count < 8 {
            hexString = "0" + hexString
        }
        return "QQ" + hexString
    }
}

extension Data {

    var monkeyking_json: [String: Any]? {
        do {
            return try JSONSerialization.jsonObject(with: self, options: .allowFragments) as? [String: Any]
        } catch {
            return nil
        }
    }
}

extension URL {

    var monkeyking_queryDictionary: [String: Any] {
        let components = URLComponents(url: self, resolvingAgainstBaseURL: false)
        guard let items = components?.queryItems else {
            return [:]
        }
        var infos = [String: Any]()
        items.forEach {
            if let value = $0.value {
                infos[$0.name] = value
            }
        }
        return infos
    }
}

extension UIImage {

    var monkeyking_compressedImageData: Data? {
        var compressionQuality: CGFloat = 0.7
        func compressedDataOfImage(_ image: UIImage) -> Data? {
            let maxHeight: CGFloat = 240.0
            let maxWidth: CGFloat = 240.0
            var actualHeight: CGFloat = image.size.height
            var actualWidth: CGFloat = image.size.width
            var imgRatio: CGFloat = actualWidth/actualHeight
            let maxRatio: CGFloat = maxWidth/maxHeight
            if actualHeight > maxHeight || actualWidth > maxWidth {
                if imgRatio < maxRatio { // adjust width according to maxHeight
                    imgRatio = maxHeight / actualHeight
                    actualWidth = imgRatio * actualWidth
                    actualHeight = maxHeight
                } else if imgRatio > maxRatio { // adjust height according to maxWidth
                    imgRatio = maxWidth / actualWidth
                    actualHeight = imgRatio * actualHeight
                    actualWidth = maxWidth
                } else {
                    actualHeight = maxHeight
                    actualWidth = maxWidth
                }
            }
            let rect = CGRect(x: 0.0, y: 0.0, width: actualWidth, height: actualHeight)
            UIGraphicsBeginImageContext(rect.size)
            defer {
                UIGraphicsEndImageContext()
            }
            image.draw(in: rect)
            let imageData = UIGraphicsGetImageFromCurrentImageContext().flatMap({
                UIImageJPEGRepresentation($0, compressionQuality)
            })
            return imageData
        }
        let fullImageData = UIImageJPEGRepresentation(self, compressionQuality)
        guard var imageData = fullImageData else { return nil }
        let minCompressionQuality: CGFloat = 0.01
        let dataLengthCeiling: Int = 31500
        while imageData.count > dataLengthCeiling && compressionQuality > minCompressionQuality {
            compressionQuality -= 0.1
            guard let image = UIImage(data: imageData) else { break }
            if let compressedImageData = compressedDataOfImage(image) {
                imageData = compressedImageData
            } else {
                break
            }
        }
        return imageData
    }
}
