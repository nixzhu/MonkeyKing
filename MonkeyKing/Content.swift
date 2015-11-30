//
//  Content.swift
//  China
//
//  Created by Shannon Wu on 11/29/15.
//  Copyright © 2015 nixWork. All rights reserved.
//

import Foundation

/// 分享的内容

public struct Content {
    /// 分享的具体内容

    public enum Media {
        case URL(NSURL)
        case Image(UIImage)
        case Audio(audioURL:NSURL, linkURL:NSURL?)
        case Video(NSURL)
    }

    public var title: String?
    public var description: String?
    public var thumbnail: UIImage?
    public var media: Media?

    ///  初始化一个新的分享内容
    public init(title: String?, description: String?, thumbnail: UIImage?, media: Media?) {
        self.title = title
        self.description = description
        self.thumbnail = thumbnail
        self.media = media
    }

    /// 初始化一个所有字段为 nil 的分享内容
    public init() {
    }
}