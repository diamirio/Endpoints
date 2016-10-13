//
//  Endpoint.swift
//  Endpoint
//
//  Created by Peter W on 13/10/2016.
//  Copyright © 2016 Tailored Apps. All rights reserved.
//

import Foundation

public protocol Endpoint {
    associatedtype RequestType: RequestEncoder
    associatedtype ResponseType: ParsableResponse
    
    var method: HTTPMethod { get }
    var path: String? { get }
}

public protocol EndpointRequest: Endpoint, RequestData {}

public struct DynamicEndpoint<Request: RequestEncoder, Response: ParsableResponse>: Endpoint {
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
