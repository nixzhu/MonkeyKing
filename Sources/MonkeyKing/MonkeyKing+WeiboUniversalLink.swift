//
//  MonkeyKing+WeiboUniversalLink.swift
//  MonkeyKing
//
//  Created by nuomi1 on 2021/1/8.
//  Copyright © 2021 nixWork. All rights reserved.
//

import Foundation

extension MonkeyKing {
    
    static func weiboSchemeLink(uuidString: String) -> URL? {
        var comps = URLComponents(string: "weibosdk://request")
        
        comps?.queryItems = [
            URLQueryItem(name: "id", value: uuidString),
            URLQueryItem(name: "sdkversion", value: "003233000"),
            URLQueryItem(name: "luicode", value: "10000360"),
            URLQueryItem(name: "lfid", value: Bundle.main.monkeyking_bundleID ?? ""),
            URLQueryItem(name: "newVersion", value: "3.3"),
        ]
        
        return comps?.url
    }
}
