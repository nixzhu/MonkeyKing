//
//  MonkeyKing+QQUniversalLink.swift
//  MonkeyKing
//
//  Created by Lex Tang on 2020/8/27.
//  Copyright © 2020 nixWork. All rights reserved.
//

import Foundation

extension MonkeyKing {

    static var qqAppSignTxid: String? {
        get {
            return UserDefaults.standard.string(forKey: _txidKey)
        }
        set {
            if newValue == nil {
                UserDefaults.standard.removeObject(forKey: _txidKey)
            } else {
                UserDefaults.standard.set(newValue, forKey: _txidKey)
            }
        }
    }

    static var qqAppSignToken: String? {
        get {
            return UserDefaults.standard.string(forKey: _tokenKey)
        }
        set {
            if newValue == nil {
                UserDefaults.standard.removeObject(forKey: _tokenKey)
            } else {
                UserDefaults.standard.set(newValue, forKey: _tokenKey)
            }
        }
    }

}

private let _txidKey = "_MonkeyKingQQAppSignTxid"
private let _tokenKey = "_MonkeyKingQQAppSignToken"
