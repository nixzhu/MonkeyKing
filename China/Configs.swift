//
//  Configs.swift
//  China
//
//  Created by Limon on 15/12/13.
//  Copyright © 2015年 nixWork. All rights reserved.
//

import Foundation

struct Configs {

    struct Weibo {
        static let appID = "1772193724"
        static let appKey = "453283216b8c885dad2cdb430c74f62a"
        static let redirectURL = "http://www.limon.top"
    }

    struct Wechat {
        static let appID = "wx4868b35061f87885"
        static let appKey = "64020361b8ec4c99936c0e3999a9f249"
    }

    struct QQ {
        static let appID = "1104881792"
    }

    struct Pocket {
        static let appID = "48363-344532f670a052acff492a25"
        static let redirectURL = "pocketapp48363:authorizationFinished" // pocketapp + $prefix + :authorizationFinished
    }

    struct Alipay {
        static let appID = "2016012101112529"
    }
}
