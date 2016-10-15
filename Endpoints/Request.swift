//
//  Request.swift
//  Endpoint
//
//  Created by Peter W on 13/10/2016.
//  Copyright © 2016 Tailored Apps. All rights reserved.
//

import Foundation

public typealias Parameters = [String: String]

public protocol RequestEncoder {
    func encode(request: URLRequest) -> URLRequest
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
        let data = DynamicRequestData(dynamicPath: dynamicPath, query: query, header: header, body: body)
        
        return data.encode(request: request)
    }
}

public struct DynamicRequestData: RequestData {
    public var dynamicPath: String?
    public var query: Parameters?
    public var header: Parameters?
    public var body: Data?
    
    public init(dynamicPath: String?=nil, query: Parameters?=nil, header: Parameters?=nil, body: Data?=nil) {
        self.dynamicPath = dynamicPath
        self.query = query
        self.header = header
        self.body = body
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
    
    public func encode(request: URLRequest) -> URLRequest {
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
}
