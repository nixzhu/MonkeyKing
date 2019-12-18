
import UIKit

class Networking {

    static let shared = Networking()

    private let session = URLSession.shared

    typealias NetworkingResponseHandler = ([String: Any]?, URLResponse?, Error?) -> Void

    enum Method: String {
        case get = "GET"
        case post = "POST"
    }

    enum ParameterEncoding {
        case url
        case urlEncodedInURL
        case json

        func encode(_ request: URLRequest, parameters: [String: Any]?) -> URLRequest {
            guard let parameters = parameters else {
                return request
            }
            guard let httpMethod = request.httpMethod else {
                return request
            }
            guard let url = request.url else {
                return request
            }
            var mutableURLRequest = request
            switch self {
            case .url, .urlEncodedInURL:
                func query(_ parameters: [String: Any]) -> String {
                    var components: [(String, String)] = []
                    for key in parameters.keys.sorted(by: <) {
                        let value = parameters[key]!
                        components += queryComponents(key, value)
                    }
                    return (components.map { "\($0)=\($1)" } as [String]).joined(separator: "&")
                }
                func encodesParametersInURL(_ method: Method) -> Bool {
                    switch self {
                    case .urlEncodedInURL:
                        return true
                    default:
                        break
                    }
                    switch method {
                    case .get:
                        return true
                    default:
                        return false
                    }
                }
                if let method = Method(rawValue: httpMethod), encodesParametersInURL(method) {
                    if var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                        let percentEncodedQuery = (urlComponents.percentEncodedQuery.map { $0 + "&" } ?? "") + query(parameters)
                        urlComponents.percentEncodedQuery = percentEncodedQuery
                        mutableURLRequest.url = urlComponents.url
                    }
                } else {
                    if mutableURLRequest.value(forHTTPHeaderField: "Content-Type") == nil {
                        mutableURLRequest.setValue(
                            "application/x-www-form-urlencoded; charset=utf-8",
                            forHTTPHeaderField: "Content-Type"
                        )
                    }
                    mutableURLRequest.httpBody = query(parameters).data(
                        using: .utf8,
                        allowLossyConversion: false
                    )
                }
            case .json:
                do {
                    let data = try JSONSerialization.data(withJSONObject: parameters)
                    mutableURLRequest.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
                    mutableURLRequest.setValue("application/json", forHTTPHeaderField: "X-Accept")
                    mutableURLRequest.httpBody = data
                } catch {
                    print("error: \(error)")
                }
            }
            return mutableURLRequest
        }

        func queryComponents(_ key: String, _ value: Any) -> [(String, String)] {
            var components: [(String, String)] = []
            if let dictionary = value as? [String: Any] {
                for (nestedKey, value) in dictionary {
                    components += queryComponents("\(key)[\(nestedKey)]", value)
                }
            } else if let array = value as? [AnyObject] {
                for value in array {
                    components += queryComponents("\(key)[]", value)
                }
            } else {
                components.append((escape(key), escape("\(value)")))
            }
            return components
        }

        func escape(_ string: String) -> String {
            let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
            let subDelimitersToEncode = "!$&'()*+,;="
            var allowedCharacterSet = CharacterSet.urlQueryAllowed
            allowedCharacterSet.remove(charactersIn: generalDelimitersToEncode + subDelimitersToEncode)
            var escaped = ""
            if #available(iOS 8.3, *) {
                escaped = string.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) ?? string
            } else {
                let batchSize = 50
                var index = string.startIndex
                while index != string.endIndex {
                    let startIndex = index
                    let endIndex = string.index(index, offsetBy: batchSize, limitedBy: string.endIndex) ?? startIndex
                    let substring = string[startIndex ..< endIndex]
                    escaped += (substring.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet as CharacterSet) ?? String(substring))
                    index = endIndex
                }
            }
            return escaped
        }
    }

    func request(_ urlString: String, method: Method, parameters: [String: Any]? = nil, encoding: ParameterEncoding = .url, headers: [String: String]? = nil, completionHandler: @escaping ([String: Any]?, URLResponse?, Error?) -> Void) {
        guard let url = URL(string: urlString) else {
            return
        }
        var mutableURLRequest = URLRequest(url: url)
        mutableURLRequest.httpMethod = method.rawValue
        if let headers = headers {
            for (headerField, headerValue) in headers {
                mutableURLRequest.setValue(headerValue, forHTTPHeaderField: headerField)
            }
        }
        let request = encoding.encode(mutableURLRequest, parameters: parameters)
        let task = session.dataTask(with: request) { data, response, error in
            var json: [String: Any]?
            defer {
                DispatchQueue.main.async {
                    completionHandler(json, response, error as Error?)
                }
            }
            if let httpResponse = response as? HTTPURLResponse,
                let data = data,
                httpResponse.url!.absoluteString.contains("api.twitter.com") {
                let contentType = httpResponse.allHeaderFields["Content-Type"] as? String
                if contentType == nil || contentType!.contains("application/json") == false {
                    let responseText = String(data: data, encoding: .utf8)
                    // TWITTER SUCKS. API WILL RETURN <application/html>
                    // oauth_token=sample&oauth_token_secret=sample&oauth_callback_confirmed=true
                    json = responseText?.queryStringParameters
                    return
                }
            }
            guard let validData = data,
                let jsonData = validData.monkeyking_json else {
                print("requst fail: JSON could not be serialized because input data was nil.")
                return
            }
            json = jsonData
        }
        task.resume()
    }

    func upload(_ urlString: String, parameters: [String: Any], headers: [String: String]? = nil, completionHandler: @escaping ([String: Any]?, URLResponse?, Error?) -> Void) {
        let tuple = urlRequestWithComponents(urlString, parameters: parameters)
        guard let request = tuple.request, let data = tuple.data else {
            return
        }
        var mutableURLRequest = request
        if let headers = headers {
            for (headerField, headerValue) in headers {
                mutableURLRequest.setValue(headerValue, forHTTPHeaderField: headerField)
            }
        }
        let uploadTask = session.uploadTask(with: mutableURLRequest, from: data) { data, response, error in
            var json: [String: Any]?
            defer {
                DispatchQueue.main.async {
                    completionHandler(json, response, error as Error?)
                }
            }
            guard let validData = data,
                let jsonData = validData.monkeyking_json else {
                print("upload fail: JSON could not be serialized because input data was nil.")
                return
            }
            json = jsonData
        }
        uploadTask.resume()
    }

    func urlRequestWithComponents(_ urlString: String, parameters: [String: Any], encoding: ParameterEncoding = .url) -> (request: URLRequest?, data: Data?) {
        guard let url = URL(string: urlString) else {
            return (nil, nil)
        }
        var mutableURLRequest = URLRequest(url: url)
        mutableURLRequest.httpMethod = Method.post.rawValue
        let boundaryConstant = "NET-POST-boundary-\(arc4random())-\(arc4random())"
        let contentType = "multipart/form-data;boundary=" + boundaryConstant
        mutableURLRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")

        var uploadData = Data()
        // add parameters
        for (key, value) in parameters {
            guard let encodeBoundaryData = "\r\n--\(boundaryConstant)\r\n".data(using: .utf8) else {
                return (nil, nil)
            }
            uploadData.append(encodeBoundaryData)
            if let imageData = value as? Data {
                let filename = arc4random()
                let filenameClause = "filename=\"\(filename)\""
                let contentDispositionString = "Content-Disposition: form-data; name=\"\(key)\";\(filenameClause)\r\n"
                let contentDispositionData = contentDispositionString.data(using: .utf8)
                uploadData.append(contentDispositionData!)
                // append content type
                let contentTypeString = "Content-Type: image/JPEG\r\n\r\n"
                guard let contentTypeData = contentTypeString.data(using: .utf8) else {
                    return (nil, nil)
                }
                uploadData.append(contentTypeData)
                uploadData.append(imageData)
            } else {
                guard let encodeDispositionData = "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)".data(using: .utf8) else {
                    return (nil, nil)
                }
                uploadData.append(encodeDispositionData)
            }
        }
        uploadData.append("\r\n--\(boundaryConstant)--\r\n".data(using: .utf8)!)
        return (encoding.encode(mutableURLRequest, parameters: nil), uploadData)
    }

    func authorizationHeader(for method: Method, urlString: String, appID: String, appKey: String, accessToken: String?, accessTokenSecret: String?, parameters: [String: Any]?, isMediaUpload: Bool) -> String {
        var authorizationParameters = [String: Any]()
        authorizationParameters["oauth_version"] = "1.0"
        authorizationParameters["oauth_signature_method"] = "HMAC-SHA1"
        authorizationParameters["oauth_consumer_key"] = appID
        authorizationParameters["oauth_timestamp"] = String(Int(Date().timeIntervalSince1970))
        authorizationParameters["oauth_nonce"] = UUID().uuidString
        if let accessToken = accessToken {
            authorizationParameters["oauth_token"] = accessToken
        }
        if let parameters = parameters {
            for (key, value) in parameters where key.hasPrefix("oauth_") {
                authorizationParameters.updateValue(value, forKey: key)
            }
        }
        var finalParameters = authorizationParameters
        if isMediaUpload {
            if let parameters = parameters {
                for (k, v) in parameters {
                    finalParameters[k] = v
                }
            }
        }
        authorizationParameters["oauth_signature"] = oauthSignature(for: method, urlString: urlString, parameters: finalParameters, appKey: appKey, accessTokenSecret: accessTokenSecret)
        let authorizationParameterComponents = authorizationParameters.urlEncodedQueryString(using: .utf8).components(separatedBy: "&").sorted()
        var headerComponents = [String]()
        for component in authorizationParameterComponents {
            let subcomponent = component.components(separatedBy: "=")
            if subcomponent.count == 2 {
                headerComponents.append("\(subcomponent[0])=\"\(subcomponent[1])\"")
            }
        }
        return "OAuth " + headerComponents.joined(separator: ", ")
    }

    func oauthSignature(for method: Method, urlString: String, parameters: [String: Any], appKey: String, accessTokenSecret tokenSecret: String?) -> String {
        let tokenSecret = tokenSecret?.urlEncodedString() ?? ""
        let encodedConsumerSecret = appKey.urlEncodedString()
        let signingKey = "\(encodedConsumerSecret)&\(tokenSecret)"
        let parameterComponents = parameters.urlEncodedQueryString(using: .utf8).components(separatedBy: "&").sorted()
        let parameterString = parameterComponents.joined(separator: "&")
        let encodedParameterString = parameterString.urlEncodedString()
        let encodedURL = urlString.urlEncodedString()
        let signatureBaseString = "\(method.rawValue)&\(encodedURL)&\(encodedParameterString)"
        let key = signingKey.data(using: .utf8)!
        let msg = signatureBaseString.data(using: .utf8)!
        let sha1 = HMAC.sha1(key: key, message: msg)!
        return sha1.base64EncodedString(options: [])
    }
}

// MARK: URLEncode

extension Dictionary {

    func urlEncodedQueryString(using encoding: String.Encoding) -> String {
        var parts = [String]()
        for (key, value) in self {
            let keyString = "\(key)".urlEncodedString()
            let valueString = "\(value)".urlEncodedString(keyString == "status")
            let query: String = "\(keyString)=\(valueString)"
            parts.append(query)
        }
        return parts.joined(separator: "&")
    }
}

extension String {

    var queryStringParameters: [String: String] {
        var parameters = [String: String]()
        let scanner = Scanner(string: self)
        var key: NSString?
        var value: NSString?
        while !scanner.isAtEnd {
            key = nil
            scanner.scanUpTo("=", into: &key)
            scanner.scanString("=", into: nil)
            value = nil
            scanner.scanUpTo("&", into: &value)
            scanner.scanString("&", into: nil)
            if let key = key as String?, let value = value as String? {
                parameters.updateValue(value, forKey: key)
            }
        }
        return parameters
    }

    func urlEncodedString(_ encodeAll: Bool = false) -> String {
        var allowedCharacterSet: CharacterSet = .urlQueryAllowed
        allowedCharacterSet.remove(charactersIn: "\n:#/?@!$&'()*+,;=")
        if !encodeAll {
            allowedCharacterSet.insert(charactersIn: "[]")
        }
        return addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)!
    }
}

public struct HMAC {

    static func sha1(key: Data, message: Data) -> Data? {
        var key = key.rawBytes
        let message = message.rawBytes
        // key
        if key.count > 64 {
            key = SHA1(message: Data(bytes: key)).calculate().rawBytes
        }
        if key.count < 64 {
            key = key + [UInt8](repeating: 0, count: 64 - key.count)
        }
        var opad = [UInt8](repeating: 0x5C, count: 64)
        for (idx, _) in key.enumerated() {
            opad[idx] = key[idx] ^ opad[idx]
        }
        var ipad = [UInt8](repeating: 0x36, count: 64)
        for (idx, _) in key.enumerated() {
            ipad[idx] = key[idx] ^ ipad[idx]
        }
        let ipadAndMessageHash = SHA1(message: Data(bytes: ipad + message)).calculate().rawBytes
        let finalHash = SHA1(message: Data(bytes: opad + ipadAndMessageHash)).calculate().rawBytes
        let mac = finalHash
        return Data(bytes: UnsafePointer<UInt8>(mac), count: mac.count)
    }
}

// MARK: SHA1

struct SHA1 {

    var message: Data

    /** Common part for hash calculation. Prepare header data. */
    func prepare(_ len: Int = 64) -> Data {
        var tmpMessage: Data = message
        // Step 1. Append Padding Bits
        tmpMessage.append([0x80]) // append one bit (Byte with one bit) to message
        // append "0" bit until message length in bits ≡ 448 (mod 512)
        while tmpMessage.count % len != (len - 8) {
            tmpMessage.append([0x00])
        }
        return tmpMessage
    }

    func calculate() -> Data {
        // var tmpMessage = self.prepare()
        let len = 64
        let h: [UInt32] = [0x6745_2301, 0xEFCD_AB89, 0x98BA_DCFE, 0x1032_5476, 0xC3D2_E1F0]
        var tmpMessage: Data = message
        // Step 1. Append Padding Bits
        tmpMessage.append([0x80]) // append one bit (Byte with one bit) to message
        // append "0" bit until message length in bits ≡ 448 (mod 512)
        while tmpMessage.count % len != (len - 8) {
            tmpMessage.append([0x00])
        }
        // hash values
        var hh = h
        // append message length, in a 64-bit big-endian integer. So now the message length is a multiple of 512 bits.
        tmpMessage.append((message.count * 8).bytes(64 / 8))
        // Process the message in successive 512-bit chunks:
        let chunkSizeBytes = 512 / 8 // 64
        var leftMessageBytes = tmpMessage.count
        var i = 0
        while i < tmpMessage.count {
            let chunk = tmpMessage.subdata(in: i ..< i + min(chunkSizeBytes, leftMessageBytes))
            // break chunk into sixteen 32-bit words M[j], 0 ≤ j ≤ 15, big-endian
            // Extend the sixteen 32-bit words into eighty 32-bit words:
            var M = [UInt32](repeating: 0, count: 80)
            for x in 0 ..< M.count {
                switch x {
                case 0 ... 15:
                    var le: UInt32 = 0
                    let range = NSRange(location: x * MemoryLayout<UInt32>.size, length: MemoryLayout<UInt32>.size)
                    (chunk as NSData).getBytes(&le, range: range)
                    M[x] = le.bigEndian
                default:
                    M[x] = rotateLeft(M[x - 3] ^ M[x - 8] ^ M[x - 14] ^ M[x - 16], n: 1)
                }
            }
            var A = hh[0], B = hh[1], C = hh[2], D = hh[3], E = hh[4]
            // Main loop
            for j in 0 ... 79 {
                var f: UInt32 = 0
                var k: UInt32 = 0
                switch j {
                case 0 ... 19:
                    f = (B & C) | ((~B) & D)
                    k = 0x5A82_7999
                case 20 ... 39:
                    f = B ^ C ^ D
                    k = 0x6ED9_EBA1
                case 40 ... 59:
                    f = (B & C) | (B & D) | (C & D)
                    k = 0x8F1B_BCDC
                case 60 ... 79:
                    f = B ^ C ^ D
                    k = 0xCA62_C1D6
                default:
                    break
                }
                let temp = (rotateLeft(A, n: 5) &+ f &+ E &+ M[j] &+ k) & 0xFFFF_FFFF
                E = D
                D = C
                C = rotateLeft(B, n: 30)
                B = A
                A = temp
            }
            hh[0] = (hh[0] &+ A) & 0xFFFF_FFFF
            hh[1] = (hh[1] &+ B) & 0xFFFF_FFFF
            hh[2] = (hh[2] &+ C) & 0xFFFF_FFFF
            hh[3] = (hh[3] &+ D) & 0xFFFF_FFFF
            hh[4] = (hh[4] &+ E) & 0xFFFF_FFFF
            i = i + chunkSizeBytes
            leftMessageBytes -= chunkSizeBytes
        }
        // Produce the final hash value (big-endian) as a 160 bit number:
        let mutableBuff = NSMutableData()
        hh.forEach {
            var i = $0.bigEndian
            mutableBuff.append(&i, length: MemoryLayout<UInt32>.size)
        }
        return mutableBuff as Data
    }
}

func arrayOfBytes<T>(_ value: T, length: Int? = nil) -> [UInt8] {
    let totalBytes = length ?? (MemoryLayout<T>.size * 8)
    let valuePointer = UnsafeMutablePointer<T>.allocate(capacity: 1)
    valuePointer.pointee = value
    let bytesPointer = valuePointer.withMemoryRebound(to: UInt8.self, capacity: 1) { $0 }
    var bytes = [UInt8](repeating: 0, count: totalBytes)
    for j in 0 ..< min(MemoryLayout<T>.size, totalBytes) {
        bytes[totalBytes - 1 - j] = (bytesPointer + j).pointee
    }
    valuePointer.deinitialize(count: totalBytes)
    valuePointer.deallocate()
    return bytes
}

func rotateLeft(_ v: UInt16, n: UInt16) -> UInt16 {
    return ((v << n) & 0xFFFF) | (v >> (16 - n))
}

func rotateLeft(_ v: UInt32, n: UInt32) -> UInt32 {
    return ((v << n) & 0xFFFF_FFFF) | (v >> (32 - n))
}

func rotateLeft(_ x: UInt64, n: UInt64) -> UInt64 {
    return (x << n) | (x >> (64 - n))
}

extension Int {

    public func bytes(_ totalBytes: Int = MemoryLayout<Int>.size) -> [UInt8] {
        return arrayOfBytes(self, length: totalBytes)
    }
}

extension Data {

    var rawBytes: [UInt8] {
        let count = self.count / MemoryLayout<UInt8>.size
        var bytesArray = [UInt8](repeating: 0, count: count)
        (self as NSData).getBytes(&bytesArray, length: count * MemoryLayout<UInt8>.size)
        return bytesArray
    }

    init(bytes: [UInt8]) {
        self.init(bytes: UnsafePointer<UInt8>(bytes), count: bytes.count)
    }

    mutating func append(_ bytes: [UInt8]) {
        append(UnsafePointer<UInt8>(bytes), count: bytes.count)
    }
}
