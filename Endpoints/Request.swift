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

public protocol Body {
    var header: Parameters? { get }
    var requestData: Data { get }
}

extension Body {
    public var header: Parameters? { return nil }
}

extension Data: Body {
    public var requestData: Data { return self }
}

extension String: Body {
    public var requestData: Data {
        guard let data = data(using: .utf8) else {
            fatalError("cannot convert string to data: \(self)")
        }
        return data
    }
}

public struct FormEncodedBody: Body {
    public var parameters: Parameters
    
    public init(parameters: Parameters) {
        self.parameters = parameters
    }
    
    public var header: Parameters? {
        return [ "Content-Type" : "application/x-www-form-urlencoded" ]
    }
    
    public var requestData: Data {
        return parameters.map { key, value in
            return "\(encode(key))=\(encode(value))"
        }.joined(separator: "&").data(using: .utf8)!
    }
    
    func encode(_ string: String) -> String {
        guard let encoded = string.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            fatalError("failed to encode param string: \(string)")
        }
        return encoded
    }
}

public struct JSONEncodedBody: Body {
    public let requestData: Data
    
    public init(jsonObject: Any) throws {
        requestData = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
    }
    
    public var header: Parameters? {
        return [ "Content-Type" : "application/json" ]
    }
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
    var body: Body? { get }
}

public extension Request {
    var query: Parameters? { return nil }
    var header: Parameters? { return body?.header }
    var body: Body? { return nil }
    
    public func encode(withBaseURL baseURL: URL) -> URLRequest {
        return encodeData(withBaseURL: baseURL)
    }
    
    func encodeData(withBaseURL baseURL: URL) -> URLRequest {
        var url = baseURL
        
        if let path = path {
            url.appendPathComponent(path)
        }
        
        if let queryItems = queryItems {
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
        urlRequest.httpBody = body?.requestData
        
        body?.header?.forEach { urlRequest.setValue($1, forHTTPHeaderField: $0) }
        header?.forEach { urlRequest.setValue($1, forHTTPHeaderField: $0) } //request header trumps body header
        
        return urlRequest
    }
    
    var queryItems: [URLQueryItem]? {
        guard let params = query else {
            return nil
        }
        
        return params.map { URLQueryItem(name: $0, value: $1) }
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
    public var body: Body?
    
    public var encode: EncodingBlock?
    public var validate: ValidationBlock?
    
    public init(_ method: HTTPMethod, _ path: String?=nil, query: Parameters?=nil, header: Parameters?=nil, body: Body?=nil, encode: EncodingBlock?=nil, validate: ValidationBlock?=nil) {
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
