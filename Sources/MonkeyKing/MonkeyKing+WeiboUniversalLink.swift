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
    
    static func weiboUniversalLink(query: String?) -> URL? {
        var ulComps = URLComponents(string: "https://open.weibo.com/weibosdk/request")
        
        ulComps?.query = query
        
        if let index = ulComps?.queryItems?.firstIndex(where: { $0.name == "id" }) {
            ulComps?.queryItems?[index].name = "objId"
        } else {
            assertionFailure()
            return nil
        }
        
        ulComps?.queryItems?.append(contentsOf: [
            URLQueryItem(name: "urltype", value: "link"),
        ])
        
        return ulComps?.url
    }
}
