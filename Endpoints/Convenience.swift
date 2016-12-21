//
//  Convenience.swift
//  Endpoints
//
//  Created by Peter W on 05/11/2016.
//  Copyright © 2016 Tailored Apps. All rights reserved.
//

import Foundation

extension URL: URLRequestEncodable {
    public var urlRequest: URLRequest {
        return URLRequest(url: self)
    }
}

extension URLRequest: URLRequestEncodable {
    public var urlRequest: URLRequest {
        return self
    }
}

public struct BasicAuthorization {
    let user: String
    let password: String
    
    public init(user: String, password: String) {
        self.user = user
        self.password = password
    }
    
    public var key: String {
        return "Authorization"
    }
    
    public var value: String {
        var value = "\(user):\(password)"
        let data = value.data(using: .utf8)!
        
        value = data.base64EncodedString(options: .endLineWithLineFeed)
        
        return "Basic \(value)"
    }
    
    public var header: Parameters {
        return [ key: value ]
    }
}

public struct DynamicCall<Response: ResponseParser>: Call {
    public typealias ResponseType = Response
    
    public typealias EncodingBlock = (inout URLRequest)->()
    public typealias ValidationBlock = (URLSessionTaskResult) throws ->()
    
    public var request: URLRequestEncodable
    
    public var validate: ValidationBlock?
    
    public init(_ request: URLRequestEncodable, validate: ValidationBlock?=nil) {
        self.request = request
        
        self.validate = validate
    }
    
    public func validate(result: URLSessionTaskResult) throws {
        try validate?(result)
    }
}

extension Result {
    public var urlError: URLError? {
        return error as? URLError
    }
    
    public var wasCancelled: Bool {
        return urlError?.code == .cancelled
    }
    
    @discardableResult
    public func onSuccess(block: (Value)->()) -> Result {
        if let value = value {
            block(value)
        }
        return self
    }
    
    @discardableResult
    public func onError(block: (Error)->()) -> Result {
        if !wasCancelled, let error = error {
            block(error)
        }
        return self
    }
}
