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
    func encode(withBaseURL baseURL: URL) -> URLRequest
}

public protocol Request: RequestEncoder, ResponseValidator {
    associatedtype ResponseType: ResponseParser
    
    var method: HTTPMethod { get }
    var path: String? { get }
    var query: Parameters? { get }
    var header: Parameters? { get }
    var body: Data? { get }
}

public extension Request {
    var dynamicPath: String? { return nil }
    var query: Parameters? { return nil }
    var header: Parameters? { return nil }
    var body: Data? { return nil }
    
    public func encode(withBaseURL baseURL: URL) -> URLRequest {
        return encodeData(withBaseURL: baseURL)
    }
    
    func encodeData(withBaseURL baseURL: URL) -> URLRequest {
        var url = baseURL
        
        if let path = path {
            url.appendPathComponent(path)
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
        
        var urlRequest = URLRequest(url: url)
        
        urlRequest.httpMethod = method.rawValue
        urlRequest.url = url
        urlRequest.httpBody = body
        urlRequest.allHTTPHeaderFields = header
        
        return urlRequest
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
    
    public func validate(result: URLSessionTaskResult) throws {
        //no validation by default
    }
}

public struct DynamicRequest<Response: ResponseParser>: Request {
    public typealias ResponseType = Response
    
    public typealias EncodingBlock = (URLRequest)->(URLRequest)
    public typealias ValidationBlock = (URLSessionTaskResult) throws ->()
    
    public var method: HTTPMethod
    public var path: String?
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
    
    public func encode(withBaseURL baseURL: URL) -> URLRequest {
        var req = encodeData(withBaseURL: baseURL)
        
        if let encode = encode {
            req = encode(req)
        }
        
        return req
    }
    
    public func validate(result: URLSessionTaskResult) throws {
        try validate?(result)
    }
}
