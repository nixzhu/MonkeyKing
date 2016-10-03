//
//  Networking.swift
//  MonkeyKing
//
//  Created by Limon on 15/9/25.
//  Copyright © 2015年 nixWork. All rights reserved.
//

import Foundation

class Networking {

    static let sharedInstance = Networking()
    fileprivate let session = URLSession.shared

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
                    let options = JSONSerialization.WritingOptions()
                    let data = try JSONSerialization.data(withJSONObject: parameters, options: options)

                    mutableURLRequest.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
                    mutableURLRequest.setValue("application/json", forHTTPHeaderField: "X-Accept")
                    mutableURLRequest.httpBody = data

                } catch let error {
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
                    let range = startIndex..<endIndex
                    
                    let substring = string.substring(with: range)
                    
                    escaped += substring.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) ?? substring
                    
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

        let task = session.dataTask(with: request, completionHandler: { (data, response, error) in

            var json: [String: Any]?

            defer {
                DispatchQueue.main.async {
                    completionHandler(json, response, error as Error?)
                }
            }

            guard let validData = data,
                let jsonData = try? JSONSerialization.jsonObject(with: validData, options: .allowFragments) as? [String: Any] else {
                    print("requst fail: JSON could not be serialized because input data was nil.")
                    return
            }

            json = jsonData
        }) 

        task.resume()
    }

    func upload(_ urlString: String, parameters: [String: Any], completionHandler: @escaping ([String: Any]?, URLResponse?, Error?) -> Void) {

        let tuple = urlRequestWithComponents(urlString, parameters: parameters)

        guard let request = tuple.request, let data = tuple.data else {
            return
        }

        let uploadTask = session.uploadTask(with: request, from: data, completionHandler: { (data, response, error) in
            var json: [String: Any]?

            defer {
                DispatchQueue.main.async {
                    completionHandler(json, response, error as Error?)
                }
            }

            guard let validData = data,
                let jsonData = try? JSONSerialization.jsonObject(with: validData, options: .allowFragments) as? [String: Any] else {
                    print("upload fail: JSON could not be serialized because input data was nil.")
                    return
            }

            json = jsonData
        }) 

        uploadTask.resume()
    }

    func urlRequestWithComponents(_ urlString: String, parameters: [String: Any], encoding: ParameterEncoding = .url) -> (request: URLRequest?, data: Data?) {

        guard let url = URL(string: urlString) else {
            return (nil, nil)
        }

        var mutableURLRequest = URLRequest(url: url)
        mutableURLRequest.httpMethod = Method.post.rawValue
        let boundaryConstant = "NET-POST-boundary-\(arc4random())-\(arc4random())"
        let contentType = "multipart/form-data;boundary="+boundaryConstant
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
}
