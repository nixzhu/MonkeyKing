//
//  MKGNetworkingProtocol.swift
//  China
//
//  Created by Limon on 15/12/5.
//  Copyright © 2015年 nixWork. All rights reserved.
//

import UIKit

public protocol MKGNetworkingProtocol: class {

    func request(URLString: String, method: MKGMethod, parameters: [String: AnyObject]?, encoding: MKGParameterEncoding, headers: [String: String]?, completionHandler: MKGNetworkingResponseHandler)

    func upload(URLString: String, parameters: [String: AnyObject], completionHandler: MKGNetworkingResponseHandler)
}


