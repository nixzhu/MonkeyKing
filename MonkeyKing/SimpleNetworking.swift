//
//  SimpleNetworking.swift
//  MonkeyKing
//
//  Created by Limon on 15/9/25.
//  Copyright © 2015年 nixWork. All rights reserved.
//

import Foundation

public typealias NetworkingResponseHandler = (NSDictionary?, NSURLResponse?, NSError?) -> Void

public enum MKGMethod: String {
    case GET
    case POST
}

public enum MKGParameterEncoding {
    case URL
    case URLEncodedInURL
    case JSON

    func encode(URLRequest: NSMutableURLRequest, parameters: [String: AnyObject]?) -> NSURLRequest {
        guard let parameters = parameters, mutableURLRequest = URLRequest.mutableCopy() as? NSMutableURLRequest  else {
            return URLRequest
        }

        switch self {
        case .URL, .URLEncodedInURL:
            func query(parameters: [String: AnyObject]) -> String {
                var components: [(String, String)] = []

                for key in parameters.keys.sort(<) {
                    let value = parameters[key]!
                    components += queryComponents(key, value)
                }

                return (components.map { "\($0)=\($1)" } as [String]).joinWithSeparator("&")
            }

            func encodesParametersInURL(method: MKGMethod) -> Bool {
                switch self {
                case .URLEncodedInURL:
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

            if let method = MKGMethod(rawValue: mutableURLRequest.HTTPMethod) where encodesParametersInURL(method) {
                if let URLComponents = NSURLComponents(URL: mutableURLRequest.URL!, resolvingAgainstBaseURL: false) {
                    let percentEncodedQuery = (URLComponents.percentEncodedQuery.map { $0 + "&" } ?? "") + query(parameters)
                    URLComponents.percentEncodedQuery = percentEncodedQuery
                    mutableURLRequest.URL = URLComponents.URL
                }
            } else {
                if mutableURLRequest.valueForHTTPHeaderField("Content-Type") == nil {
                    mutableURLRequest.setValue(
                        "application/x-www-form-urlencoded; charset=utf-8",
                        forHTTPHeaderField: "Content-Type"
                    )
                }

                mutableURLRequest.HTTPBody = query(parameters).dataUsingEncoding(
                    NSUTF8StringEncoding,
                    allowLossyConversion: false
                )
            }
        case .JSON:
            do {
                let options = NSJSONWritingOptions()
                let data = try NSJSONSerialization.dataWithJSONObject(parameters, options: options)

                mutableURLRequest.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
                mutableURLRequest.setValue("application/json", forHTTPHeaderField: "X-Accept")
                mutableURLRequest.HTTPBody = data
            } catch {
            }

        }

        return mutableURLRequest
    }

    func queryComponents(key: String, _ value: AnyObject) -> [(String, String)] {
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

    func escape(string: String) -> String {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="

        let allowedCharacterSet = NSCharacterSet.URLQueryAllowedCharacterSet().mutableCopy() as! NSMutableCharacterSet
        allowedCharacterSet.removeCharactersInString(generalDelimitersToEncode + subDelimitersToEncode)

        var escaped = ""

        if #available(iOS 8.3, *) {
            escaped = string.stringByAddingPercentEncodingWithAllowedCharacters(allowedCharacterSet) ?? string
        } else {
            let batchSize = 50
            var index = string.startIndex

            while index != string.endIndex {
                let startIndex = index
                let endIndex = index.advancedBy(batchSize, limit: string.endIndex)
                let range = Range(start: startIndex, end: endIndex)

                let substring = string.substringWithRange(range)

                escaped += substring.stringByAddingPercentEncodingWithAllowedCharacters(allowedCharacterSet) ?? substring

                index = endIndex
            }
        }

        return escaped
    }
}

class SimpleNetworking {

    static let sharedInstance = SimpleNetworking()
    private let session = NSURLSession.sharedSession()

    func request(URLString: String, method: MKGMethod, parameters: [String: AnyObject]? = nil, encoding: MKGParameterEncoding = .URL, headers: [String: String]? = nil, completionHandler: NetworkingResponseHandler) {

        guard MonkeyKing.networkingDelegate == nil else {
            MonkeyKing.networkingDelegate?.request(URLString, method: method, parameters: parameters, encoding: encoding, headers: headers, completionHandler: completionHandler)
            return
        }

        guard let URL = NSURL(string: URLString) else {
            return
        }

        let mutableURLRequest = NSMutableURLRequest(URL: URL)
        mutableURLRequest.HTTPMethod = method.rawValue

        if let headers = headers {
            for (headerField, headerValue) in headers {
                mutableURLRequest.setValue(headerValue, forHTTPHeaderField: headerField)
            }
        }

        let request = encoding.encode(mutableURLRequest, parameters: parameters)

        let task = session.dataTaskWithRequest(request) { (data, response, error) -> Void in

            var JSON: NSDictionary?

            defer {
                completionHandler(JSON, response, error)
            }

            guard let validData = data,
                let JSONData = try? NSJSONSerialization.JSONObjectWithData(validData, options: .AllowFragments) as? NSDictionary else {
                    print("JSON could not be serialized because input data was nil.")
                    return
            }

            JSON = JSONData
        }

        task.resume()
    }


    func upload(URLString: String, parameters: [String: AnyObject], completionHandler: NetworkingResponseHandler) {

        guard MonkeyKing.networkingDelegate == nil else {
            MonkeyKing.networkingDelegate?.upload(URLString, parameters: parameters, completionHandler: completionHandler)
            return
        }

        let tuple = urlRequestWithComponents(URLString, parameters: parameters)

        guard let request = tuple.request, let data = tuple.data else {
            return
        }

        let uploadTask = session.uploadTaskWithRequest(request, fromData: data) { (data, response, error) -> Void in
            var JSON: NSDictionary?

            defer {
                completionHandler(JSON, response, error)
            }

            guard let validData = data,
                let JSONData = try? NSJSONSerialization.JSONObjectWithData(validData, options: .AllowFragments) as? NSDictionary else {
                    print("JSON could not be serialized because input data was nil.")
                    return
            }

            JSON = JSONData
        }

        uploadTask.resume()
    }

    private func urlRequestWithComponents(URLString: String, parameters: [String: AnyObject], encoding: MKGParameterEncoding = .URL) -> (request: NSURLRequest?, data: NSData?) {

        guard let URL = NSURL(string: URLString) else {
            return (nil, nil)
        }

        // create url request to send
        let mutableURLRequest = NSMutableURLRequest(URL: URL)
        mutableURLRequest.HTTPMethod = MKGMethod.POST.rawValue
        let boundaryConstant = "NET-POST-boundary-\(arc4random())-\(arc4random())"
        let contentType = "multipart/form-data;boundary="+boundaryConstant
        mutableURLRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")

        let uploadData = NSMutableData()

        // add parameters
        for (key, value) in parameters {

            guard let encodeBoundaryData = "\r\n--\(boundaryConstant)\r\n".dataUsingEncoding(NSUTF8StringEncoding) else {
                return (nil, nil)
            }

            uploadData.appendData(encodeBoundaryData)

            if let imageData = value as? NSData {

                let filename = arc4random()
                let filenameClause = "filename=\"\(filename)\""
                let contentDispositionString = "Content-Disposition: form-data; name=\"\(key)\";\(filenameClause)\r\n"
                let contentDispositionData = contentDispositionString.dataUsingEncoding(NSUTF8StringEncoding)
                uploadData.appendData(contentDispositionData!)

                // append content type
                let contentTypeString = "Content-Type: image/JPEG\r\n\r\n"
                guard let contentTypeData = contentTypeString.dataUsingEncoding(NSUTF8StringEncoding) else {
                    return (nil, nil)
                }
                uploadData.appendData(contentTypeData)
                uploadData.appendData(imageData)
                
            } else{
                
                guard let encodeDispositionData = "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)".dataUsingEncoding(NSUTF8StringEncoding) else {
                    return (nil, nil)
                }
                uploadData.appendData(encodeDispositionData)
            }
        }
        
        uploadData.appendData("\r\n--\(boundaryConstant)--\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        
        return (encoding.encode(mutableURLRequest, parameters: nil), uploadData)
    }
    
}
