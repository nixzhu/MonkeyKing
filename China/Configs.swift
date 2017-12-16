
import Foundation

struct Configs {

    struct Weibo {
        static let appID = "1772193724"
        static let appKey = "453283216b8c885dad2cdb430c74f62a"
        static let redirectURL = "http://www.limon.top"
    }

    struct WeChat {
        static let appID = "wx4868b35061f87885"
        static let appKey = "64020361b8ec4c99936c0e3999a9f249"
        static let miniAppID = "gh_d43f693ca31f"
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

    struct Twitter {
        static let appID = "bFSwxYoVEFn1G9VhooO3grNv1"
        static let appKey = "YxBInrlvGoMPJjN9Xa4pBeCVILgz8qTXYlNdvJzzYlt9ingbZ2"
        static let redirectURL = "https://github.com/fyl00/MonkeyKing"
    }
}
