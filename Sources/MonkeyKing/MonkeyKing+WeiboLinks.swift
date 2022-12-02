import Foundation

extension MonkeyKing {
    
    static func weiboSchemeLink(uuidString: String) -> URL? {
        var components = URLComponents(string: "weibosdk://request")
        
        components?.queryItems = [
            .init(name: "id", value: uuidString),
            .init(name: "sdkversion", value: "003233000"),
            .init(name: "luicode", value: "10000360"),
            .init(name: "lfid", value: Bundle.main.monkeyking_bundleID ?? ""),
            .init(name: "newVersion", value: "3.3"),
        ]
        
        return components?.url
    }
    
    static func weiboUniversalLink(query: String?, authItems: [String: Any]) -> URL? {
        var components = URLComponents(string: "https://open.weibo.com/weibosdk/request")
        
        components?.query = query
        
        if let index = components?.queryItems?.firstIndex(where: { $0.name == "id" }) {
            components?.queryItems?[index].name = "objId"
        } else {
            assertionFailure()
            return nil
        }
        if let index = components?.queryItems?.firstIndex(where: { $0.name == "sdkversion" }) {
            components?.queryItems?[index].value = "3.3.4"
        } else {
            assertionFailure()
            return nil
        }
        
        components?.queryItems?.append(
            .init(name: "urltype", value: "link")
        )
        guard let sdkiOS16AppAttachment = authItems["sdkiOS16AppAttachment"] as? [String: Any],
              let sdkiOS16attachment = authItems["sdkiOS16attachment"] as? [String: Any] else {
            assertionFailure()
            return nil
        }
        guard let data1 = try? PropertyListSerialization.data(fromPropertyList: sdkiOS16AppAttachment, format: .xml, options: 0),
              let data2 = try? PropertyListSerialization.data(fromPropertyList: sdkiOS16attachment, format: .xml, options: 0) else {
            assertionFailure()
            return nil
        }
        components?.queryItems?.append(
            .init(name: "sdkiOS16AppAttachment", value: data1.base64EncodedString())
        )
        components?.queryItems?.append(
            .init(name: "sdkiOS16attachment", value: data2.base64EncodedString())
        )
        
        return components?.url
    }
}
