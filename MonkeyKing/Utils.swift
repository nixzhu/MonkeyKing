//
//  Utils.swift
//  China
//
//  Created by Shannon Wu on 11/29/15.
//  Copyright © 2015 nixWork. All rights reserved.
//

import Foundation

extension NSBundle {

    var monkeyking_displayName: String? {

        func getNameByInfo(info: [String:AnyObject]) -> String? {

            guard let displayName = info["CFBundleDisplayName"] as? String else {
                return info["CFBundleName"] as? String
            }

            return displayName
        }

        guard let info = localizedInfoDictionary ?? infoDictionary else {
            return nil
        }

        return getNameByInfo(info)
    }

    var monkeyking_bundleID: String? {
        return objectForInfoDictionaryKey("CFBundleIdentifier") as? String
    }
}

extension String {

    var monkeyking_base64EncodedString: String? {
        return dataUsingEncoding(NSUTF8StringEncoding)?.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
    }

    var monkeyking_urlEncodedString: String? {
        return stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet())
    }

    var monkeyking_base64AndURLEncodedString: String? {
        return monkeyking_base64EncodedString?.monkeyking_urlEncodedString
    }

    var monkeyking_QQCallbackName: String {

        var hexString = String(format: "%02llx", (self as NSString).longLongValue)
        while hexString.characters.count < 8 {
            hexString = "0" + hexString
        }

        return "QQ" + hexString
    }
}

extension NSURL {

    var monkeyking_queryInfo: [String:String] {

        var info = [String: String]()

        if let querys = query?.componentsSeparatedByString("&") {
            for query in querys {
                let keyValuePair = query.componentsSeparatedByString("=")
                if keyValuePair.count == 2 {
                    let key = keyValuePair[0]
                    let value = keyValuePair[1]

                    info[key] = value
                }
            }
        }

        return info
    }
}
