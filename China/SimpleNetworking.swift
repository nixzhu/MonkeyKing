//
//  SimpleNetworking.swift
//  MonkeyKing
//
//  Created by Limon on 15/9/25.
//  Copyright © 2015年 nixWork. All rights reserved.
//

import Foundation
import MonkeyKing

class SimpleNetworking {

    static let sharedInstance = SimpleNetworking()
    private let session = NSURLSession.sharedSession()

    enum Method: String {
        case GET = "GET"
        case POST = "POST"
    }

    func request(URL: NSURL, method: Method, parameters: [String: AnyObject]? = nil, completionHandler: MonkeyKing.SerializeResponse) {

        let mutableURLRequest = NSMutableURLRequest(URL: URL)
        mutableURLRequest.HTTPMethod = method.rawValue

        let request = encode(mutableURLRequest, parameters: parameters)

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


    func upload(URL: NSURL, parameters: [String: AnyObject], completionHandler: MonkeyKing.SerializeResponse) {

        let tuple = urlRequestWithComponents(URL.absoluteString, parameters: parameters)

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

    private func encode(URLRequest: NSMutableURLRequest, parameters: [String: AnyObject]?) -> NSURLRequest {
        if parameters == nil {
            return URLRequest
        }

        var mutableURLRequest: NSMutableURLRequest! = URLRequest.mutableCopy() as! NSMutableURLRequest
        func query(parameters: [String: AnyObject]) -> String {
            var components: [(String, String)] = []

            for key in Array(parameters.keys).sort(<) {
                let value: AnyObject! = parameters[key]
                components += queryComponents(key, value)
            }

            return (components.map { "\($0)=\($1)" } as [String]).joinWithSeparator("&")
        }

        let method = Method(rawValue: mutableURLRequest.HTTPMethod)!

        switch method {

            case .GET:
                if let URLComponents = NSURLComponents(URL: mutableURLRequest.URL!, resolvingAgainstBaseURL: false) {
                    URLComponents.percentEncodedQuery = (URLComponents.percentEncodedQuery != nil ? URLComponents.percentEncodedQuery! + "&" : "") + query(parameters!)
                    mutableURLRequest.URL = URLComponents.URL
                }

            default:

                do {
                    let options = NSJSONWritingOptions()
                    let data = try NSJSONSerialization.dataWithJSONObject(parameters!, options: options)

                    mutableURLRequest.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
                    mutableURLRequest.setValue("application/json", forHTTPHeaderField: "X-Accept")
                    mutableURLRequest.HTTPBody = data
                } catch {
                    print("SimpleNetworking: HTTPBody Encode")
                }

    //            if mutableURLRequest.valueForHTTPHeaderField("Content-Type") == nil {
    //                mutableURLRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    //            }
    //            mutableURLRequest.HTTPBody = query(parameters!).dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
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
                components.appendContentsOf([(escape(key), escape("\(value)"))])
            }
            
            return components
        }
        
        func escape(string: String) -> String {
            let legalURLCharactersToBeEscaped: CFStringRef = ":/?&=;+!@#$()',*"
            return CFURLCreateStringByAddingPercentEscapes(nil, string, nil, legalURLCharactersToBeEscaped, CFStringBuiltInEncodings.UTF8.rawValue) as String
        }
        
        return mutableURLRequest
    }

    private func urlRequestWithComponents(URLString: String, parameters: [String: AnyObject]) -> (request: NSURLRequest?, data: NSData?) {

        guard let URL = NSURL(string: URLString) else {
            return (nil, nil)
        }

        // create url request to send
        let mutableURLRequest = NSMutableURLRequest(URL: URL)
        mutableURLRequest.HTTPMethod = Method.POST.rawValue
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

        return (encode(mutableURLRequest, parameters: nil), uploadData)
    }

}
