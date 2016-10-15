//
//  Endpoint.swift
//  Endpoint
//
//  Created by Peter W on 13/10/2016.
//  Copyright © 2016 Tailored Apps. All rights reserved.
//

import Foundation

public protocol Endpoint {
    //TODO: Let Endpoint optionally constrain API Type
    associatedtype RequestType: RequestEncoder
    associatedtype ResponseType: ResponseParser
    
    var method: HTTPMethod { get }
    var path: String? { get }
}

public protocol Request: Endpoint, RequestData {
    //FIXME: this seems to be ignored by the compiler. should probable work with Swift 4
    //https://github.com/apple/swift/blob/master/docs/GenericsManifesto.md
    typealias RequestType = Self
}

public struct DynamicEndpoint<Request: RequestEncoder, Response: ResponseParser>: Endpoint {
    public typealias RequestType = Request
    public typealias ResponseType = Response
    
    public var method: HTTPMethod
    public var path: String?
    
    public init(_ method: HTTPMethod, _ path: String?) {
        self.method = method
        self.path = path
    }
}

public enum HTTPMethod: String {
    case get     = "GET"
    case post    = "POST"
    case put     = "PUT"
    case patch   = "PATCH"
    case delete  = "DELETE"
    case head    = "HEAD"
    case options = "OPTIONS"
    case trace   = "TRACE"
    case connect = "CONNECT"
}
