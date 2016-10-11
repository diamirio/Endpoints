//
//  PWHTTPRequest.swift
//  Pods
//
//  Created by Thomas Koller on 04/10/16.
//
//

import Foundation
import Alamofire

public class PWHTTPRequest<T: DataParsable> {
    public let method: Alamofire.HTTPMethod
    public let baseURL: NSURL
    public let path: String
    public var URL: URL {
        return baseURL.appendingPathComponent(path)!
    }
    
    public let encoding: ParameterEncoding
    public let parameters: [String: AnyObject]
    public let headers: [String: String]
    
    public let completion: (PWHTTPResult<T>) -> Void
    
    weak var activeRequest: DataRequest?
    
    public init(_ method: Alamofire.HTTPMethod, baseURL: NSURL, path: String, parameters: [String : AnyObject]? = nil, headers: [String : String]? = nil, encoding:ParameterEncoding? = nil, completion: @escaping (PWHTTPResult<T>) -> Void) {
        self.method = method
        self.baseURL = baseURL
        self.path = path
        self.encoding = encoding ?? (method == .get ? URLEncoding.default : JSONEncoding.default)
        self.parameters = parameters ?? [:]
        self.headers = headers ?? [:]
        self.completion = completion
    }
}

extension PWHTTPRequest: URLRequestConvertible {
    
    public func asURLRequest() throws -> URLRequest {
        var urlRequest = URLRequest(url: URL)
        
        urlRequest.httpMethod = method.rawValue
        
        for (headerField, headerValue) in headers {
            urlRequest.setValue(headerValue, forHTTPHeaderField: headerField)
        }
        
        let encodedURLRequest = try encoding.encode(urlRequest, with: parameters).asURLRequest()
        return encodedURLRequest
        
    }
}
