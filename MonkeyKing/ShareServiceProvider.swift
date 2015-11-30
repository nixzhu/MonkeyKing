//
//  ShareServiceProvider.swift
//  China
//
//  Created by Shannon Wu on 11/29/15.
//  Copyright © 2015 nixWork. All rights reserved.
//

import Foundation

/// 第三方分享后的回调, succeed 用来标示回调是否成功
public typealias ShareCompletionHandler = (succeed:Bool) -> Void
/// 网络返回的回调
public typealias NetworkResponseHandler = (NSDictionary?, NSURLResponse?, NSError?) -> Void

/// 提供第三方分享或者认证需要实现的接口
public protocol ShareServiceProvider: class {
    var oauthCompletionHandler: NetworkResponseHandler? { get }
    /// 是否支持分享这种内容
    func canShareContent(content: Content) -> Bool
    /// 分享内容到第三方平台
    func shareContent(content: Content, completionHandler: ShareCompletionHandler?) throws
    /// 第三方平台认证
    func OAuth(completionHandler: NetworkResponseHandler) throws
    /// 第三方平台认证后的回调
    func handleOpenURL(URL: NSURL) -> Bool
}

/// 第三方分享错误抛出异常
enum ShareError: ErrorType {
    /// 分型的内容不合法
    case ContentNotLegal
    /// 在分享前数据格式化的过程中发生错误
    case FormattingError
    /// 无法打开分享的链接
    case AppNotInstalled
    /// 第三方服务提供者内部错误
    case InternalError
    /// 没有选择分享目的地
    case DestinationNotPointed
}