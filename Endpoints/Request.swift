//
//  Request.swift
//  Endpoint
//
//  Created by Peter W on 13/10/2016.
//  Copyright © 2016 Tailored Apps. All rights reserved.
//

import Foundation

public typealias Parameters = [String: String]
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

public protocol RequestEncoder {
    func encode(request: URLRequest) -> URLRequest
}

public struct NoOpRequestEncoder: RequestEncoder {
    public func encode(request: URLRequest) -> URLRequest {
        return request
    }
}

public protocol RequestData: RequestEncoder {
    var dynamicPath: String? { get }
    var query: Parameters? { get }
    var header: Parameters? { get }
    var body: Data? { get }
}

public extension RequestData {
    var dynamicPath: String? { return nil }
    var query: Parameters? { return nil }
    var header: Parameters? { return nil }
    var body: Data? { return nil }
    
    public func encode(request: URLRequest) -> URLRequest {
        return encodeData(request: request)
    }
    
    public func encodeData(request: URLRequest) -> URLRequest {
        guard var url = request.url else {
            fatalError("cannot encode request without url")
        }
        
        var encoded = request
        
        if let dynamicPath = dynamicPath {
            url = url.appendingPathComponent(dynamicPath)
        }
        
        if let queryItems = createQueryItems() {
            guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                fatalError("failed to parse url components for \(url)")
            }
            
            urlComponents.queryItems = queryItems
            
            guard let queryUrl = urlComponents.url else {
                fatalError("invalid query")
            }
            url = queryUrl
        }
        
        encoded.url = url
        encoded.httpBody = body
        encoded.allHTTPHeaderFields = header
        
        return encoded
    }
    
    private func createQueryItems() -> [URLQueryItem]? {
        guard let params = query else {
            return nil
        }
        
        var items = [URLQueryItem]()
        for param in params {
            let queryItem = URLQueryItem(name: param.key, value: param.value)
            
            items.append(queryItem)
        }
        
        return items
    }
}

public protocol Endpoint: ResponseValidator {
    //TODO: Let Endpoint optionally constrain API Type
    associatedtype RequestType: RequestEncoder
    associatedtype ResponseType: ResponseParser
    
    var method: HTTPMethod { get }
    var path: String? { get }
}

extension Endpoint {
    public func validate(result: SessionTaskResult) throws {
        //no validation by default, override to implement endpoint specific validation
    }
}

public protocol Request: Endpoint, RequestData {
    //setting the RequestType to self seems to be ignored by the compiler. should probably work with Swift 4
    //https://github.com/apple/swift/blob/master/docs/GenericsManifesto.md
    //so typealias RequestType = Self doesn't work
    //Workaround: Set default to NoOp
    associatedtype RequestType: RequestEncoder = NoOpRequestEncoder
}

extension Request {
    func encode(withBaseURL baseURL: URL) -> URLRequest {
        var url = baseURL
        
        if let path = path {
            guard let urlWithPath = URL(string: path, relativeTo: url) else {
                fatalError("invalid path \(path)")
            }
            url = urlWithPath
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        
        return self.encode(request: urlRequest)
    }
}

public struct EndpointRequest<E: Endpoint, R: RequestEncoder>: Request {
    public typealias ResponseType = E.ResponseType
    
    public let endpoint: E
    public let requestEncoder: R?

    public init(endpoint: E, requestEncoder: R?=nil) {
        self.endpoint = endpoint
        self.requestEncoder = requestEncoder
    }
    
    public var path: String? {
        return endpoint.path
    }
    
    public var method: HTTPMethod {
        return endpoint.method
    }
    
    public func encode(request: URLRequest) -> URLRequest {
        return requestEncoder?.encode(request: request) ?? request
    }
    
    public func validate(result: SessionTaskResult) throws {
        try endpoint.validate(result: result)
    }
}

public struct DynamicRequest<Response: ResponseParser>: Request {
    public typealias RequestType = DynamicRequest
    public typealias ResponseType = Response
    
    public typealias EncodingBlock = (URLRequest)->(URLRequest)
    public typealias ValidationBlock = (SessionTaskResult) throws ->()
    
    //Endpoint
    public var method: HTTPMethod
    public var path: String?
    
    //RequestData
    public var dynamicPath: String? //not required here, can use path instead
    public var query: Parameters?
    public var header: Parameters?
    public var body: Data?
    
    public var encode: EncodingBlock?
    public var validate: ValidationBlock?
    
    public init(_ method: HTTPMethod, _ path: String?=nil, query: Parameters?=nil, header: Parameters?=nil, body: Data?=nil, encode: EncodingBlock?=nil, validate: ValidationBlock?=nil) {
        self.method = method
        self.path = path
        
        self.query = query
        self.header = header
        self.body = body
        
        self.validate = validate
        self.encode = encode
    }
    
    public func encode(request: URLRequest) -> URLRequest {
        var req = encodeData(request: request)
        
        if let encode = encode {
            req = encode(req)
        }
        
        return req
    }
    
    public func validate(result: SessionTaskResult) throws {
        try validate?(result)
    }
}
