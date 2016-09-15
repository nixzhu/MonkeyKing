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

    typealias NetworkingResponseHandler = (NSDictionary?, URLResponse?, NSError?) -> Void
    
    enum Method: String {
        case GET
        case POST
    }

    enum ParameterEncoding {
        case url
        case urlEncodedInURL
        case json

        func encode(_ URLRequest: NSMutableURLRequest, parameters: [String: AnyObject]?) -> Foundation.URLRequest {
            guard let parameters = parameters, let mutableURLRequest = URLRequest.mutableCopy() as? NSMutableURLRequest  else {
                return URLRequest as URLRequest
            }

            switch self {
            case .url, .urlEncodedInURL:
                func query(_ parameters: [String: AnyObject]) -> String {
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
                    case .GET:
                        return true
                    default:
                        return false
                    }
                }

                if let method = Method(rawValue: mutableURLRequest.httpMethod) , encodesParametersInURL(method) {
                    if let URLComponents = URLComponents(url: mutableURLRequest.url!, resolvingAgainstBaseURL: false) {
                        let percentEncodedQuery = (URLComponents.percentEncodedQuery.map { $0 + "&" } ?? "") + query(parameters)
                        URLComponents.percentEncodedQuery = percentEncodedQuery
                        mutableURLRequest.url = URLComponents.url
                    }
                } else {
                    if mutableURLRequest.value(forHTTPHeaderField: "Content-Type") == nil {
                        mutableURLRequest.setValue(
                            "application/x-www-form-urlencoded; charset=utf-8",
                            forHTTPHeaderField: "Content-Type"
                        )
                    }

                    mutableURLRequest.httpBody = query(parameters).data(
                        using: String.Encoding.utf8,
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
                } catch {
                }

            }

            return mutableURLRequest as URLRequest
        }

        func queryComponents(_ key: String, _ value: AnyObject) -> [(String, String)] {
            var components: [(String, String)] = []

            if let dictionary = value as? [String: AnyObject] {
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

            let allowedCharacterSet = (CharacterSet.urlQueryAllowed as NSCharacterSet).mutableCopy() as! NSMutableCharacterSet
            allowedCharacterSet.removeCharacters(in: generalDelimitersToEncode + subDelimitersToEncode)

            var escaped = ""

            if #available(iOS 8.3, *) {
                escaped = string.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet as CharacterSet) ?? string

            } else {
                let batchSize = 50
                var index = string.startIndex
                
                while index != string.endIndex {
                    let startIndex = index
                    let endIndex = <#T##Collection corresponding to `index`##Collection#>.index(index, offsetBy: batchSize, limitedBy: string.endIndex)
                    let range = startIndex..<endIndex
                    
                    let substring = string.substring(with: range)
                    
                    escaped += substring.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) ?? substring
                    
                    index = endIndex
                }
            }
            
            return escaped
        }
    }

    func request(_ URLString: String, method: Method, parameters: [String: AnyObject]? = nil, encoding: ParameterEncoding = .url, headers: [String: String]? = nil, completionHandler: @escaping (NSDictionary?, URLResponse?, NSError?) -> Void) {

        guard let URL = URL(string: URLString) else {
            return
        }

        let mutableURLRequest = NSMutableURLRequest(url: URL)
        mutableURLRequest.httpMethod = method.rawValue

        if let headers = headers {
            for (headerField, headerValue) in headers {
                mutableURLRequest.setValue(headerValue, forHTTPHeaderField: headerField)
            }
        }

        let request = encoding.encode(mutableURLRequest, parameters: parameters)

        let task = session.dataTask(with: request, completionHandler: { (data, response, error) -> Void in

            var JSON: NSDictionary?

            defer {
                DispatchQueue.main.async {
                    completionHandler(JSON, response, error as NSError?)
                }
            }

            guard let validData = data,
                let JSONData = try? JSONSerialization.jsonObject(with: validData, options: .allowFragments) as? NSDictionary else {
                    print("JSON could not be serialized because input data was nil.")
                    return
            }

            JSON = JSONData
        }) 

        task.resume()
    }

    func upload(_ URLString: String, parameters: [String: AnyObject], completionHandler: @escaping (NSDictionary?, URLResponse?, NSError?) -> Void) {

        let tuple = urlRequestWithComponents(URLString, parameters: parameters)

        guard let request = tuple.request, let data = tuple.data else {
            return
        }

        let uploadTask = session.uploadTask(with: request, from: data, completionHandler: { (data, response, error) -> Void in
            var JSON: NSDictionary?

            defer {
                DispatchQueue.main.async {
                    completionHandler(JSON, response, error as NSError?)
                }
            }

            guard let validData = data,
                let JSONData = try? JSONSerialization.jsonObject(with: validData, options: .allowFragments) as? NSDictionary else {
                    print("JSON could not be serialized because input data was nil.")
                    return
            }

            JSON = JSONData
        }) 

        uploadTask.resume()
    }

    func urlRequestWithComponents(_ URLString: String, parameters: [String: AnyObject], encoding: ParameterEncoding = .url) -> (request: URLRequest?, data: Data?) {

        guard let URL = URL(string: URLString) else {
            return (nil, nil)
        }

        let mutableURLRequest = NSMutableURLRequest(url: URL)
        mutableURLRequest.httpMethod = Method.POST.rawValue
        let boundaryConstant = "NET-POST-boundary-\(arc4random())-\(arc4random())"
        let contentType = "multipart/form-data;boundary="+boundaryConstant
        mutableURLRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")

        let uploadData = NSMutableData()

        // add parameters
        for (key, value) in parameters {

            guard let encodeBoundaryData = "\r\n--\(boundaryConstant)\r\n".data(using: String.Encoding.utf8) else {
                return (nil, nil)
            }

            uploadData.append(encodeBoundaryData)

            if let imageData = value as? Data {

                let filename = arc4random()
                let filenameClause = "filename=\"\(filename)\""
                let contentDispositionString = "Content-Disposition: form-data; name=\"\(key)\";\(filenameClause)\r\n"
                let contentDispositionData = contentDispositionString.data(using: String.Encoding.utf8)
                uploadData.append(contentDispositionData!)

                // append content type
                let contentTypeString = "Content-Type: image/JPEG\r\n\r\n"
                guard let contentTypeData = contentTypeString.data(using: String.Encoding.utf8) else {
                    return (nil, nil)
                }
                uploadData.append(contentTypeData)
                uploadData.append(imageData)

            } else{

                guard let encodeDispositionData = "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)".data(using: String.Encoding.utf8) else {
                    return (nil, nil)
                }
                uploadData.append(encodeDispositionData)
            }
        }

        uploadData.append("\r\n--\(boundaryConstant)--\r\n".data(using: String.Encoding.utf8)!)

        return (encoding.encode(mutableURLRequest, parameters: nil), uploadData as Data)
    }
}
