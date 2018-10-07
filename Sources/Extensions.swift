
import Foundation
import MobileCoreServices

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
        let CFBundleDisplayName = (localizedInfoDictionary?["CFBundleDisplayName"] ?? infoDictionary?["CFBundleDisplayName"]) as? String
        let CFBundleName = (localizedInfoDictionary?["CFBundleName"] ?? infoDictionary?["CFBundleName"]) as? String

        return CFBundleDisplayName ?? CFBundleName
    }

    var monkeyking_bundleID: String? {
        return object(forInfoDictionaryKey: "CFBundleIdentifier") as? String
    }
}

extension String {

    var monkeyking_base64EncodedString: String? {
        return data(using: .utf8)?.base64EncodedString()
    }

    var monkeyking_urlEncodedString: String? {
        return addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
    }

    var monkeyking_base64AndURLEncodedString: String? {
        return monkeyking_base64EncodedString?.monkeyking_urlEncodedString
    }

    var monkeyking_urlDecodedString: String? {
        return replacingOccurrences(of: "+", with: " ").removingPercentEncoding
    }

    var monkeyking_qqCallbackName: String {
        let hexString = String(format: "%08llx", (self as NSString).longLongValue)

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
                $0.jpegData(compressionQuality: compressionQuality)
            })
            return imageData
        }
        let fullImageData = self.jpegData(compressionQuality: compressionQuality)
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

    func monkeyking_resetSizeOfImageData(maxSize: Int) -> Data? {

        if let imageData = self.jpegData(compressionQuality: 1.0),
            imageData.count <= maxSize {
            return imageData
        }

        func compressedDataOfImage(_ image: UIImage?) -> Data? {

            guard let image = image else {
                return nil
            }

            let imageData = image.binaryCompression(to: maxSize)

            if imageData == nil {
                let currentMiniIamgeDataSize = self.jpegData(compressionQuality: 0.01)?.count ?? 0
                let proportion = CGFloat(currentMiniIamgeDataSize / maxSize)
                let newWidth = image.size.width * scale / proportion
                let newHeight = image.size.height * scale / proportion
                let newSize = CGSize(width: newWidth, height: newHeight)

                UIGraphicsBeginImageContext(newSize)
                image.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
                let newImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()

                return compressedDataOfImage(newImage)
            }
            return imageData
        }
        return compressedDataOfImage(self)
    }

    private func binaryCompression(to maxSize: Int) -> Data? {

        var compressionQualitys = [CGFloat](repeating: 0, count: 100)
        var i = compressionQualitys.count + 1
        compressionQualitys = compressionQualitys.map { (_) -> CGFloat in
            let newValue = CGFloat(i) / CGFloat(compressionQualitys.count + 1)
            i -= 1

            return newValue
        }

        var imageData: Data? = self.jpegData(compressionQuality: 1)

        var outPutImageData: Data? = nil

        var start = 0
        var end = compressionQualitys.count - 1
        var index = 0

        var difference = Int.max

        while start <= end {

            index = start + (end - start) / 2

            imageData = self.jpegData(compressionQuality: compressionQualitys[index])

            let imageDataSize = imageData?.count ?? 0

            if imageDataSize > maxSize {

                start = index + 1

            } else if imageDataSize < maxSize {

                if (maxSize - imageDataSize) < difference {
                    difference = (maxSize - imageDataSize)
                    outPutImageData = imageData
                }

                if index <= 0 {
                    break
                }
                end = index - 1
            } else {
                break
            }
        }
        return outPutImageData
    }
}

extension UIPasteboard {
    /// Fetch old text on pasteboard
    var oldText: String? {
        /// From iOS 8 to iOS 11, UIPasteboardTypeListString contains two elements: public.text, public.utf8-plain-text
        guard let typeListString = UIPasteboard.typeListString as? [String] else { return nil }
        guard UIPasteboard.general.contains(pasteboardTypes: typeListString) else { return nil }
        return UIPasteboard.general.string
    }
}
