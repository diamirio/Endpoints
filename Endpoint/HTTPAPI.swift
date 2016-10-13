//
//  API.swift
//  Endpoint
//
//  Created by Peter W on 10/10/2016.
//  Copyright © 2016 Tailored Apps. All rights reserved.
//

import Foundation

public enum APIError: Error {
    case unacceptableStatus(code: Int)
    case parsingError(description: String)
    case serverError(description: String)
}

public enum EndpointMethod: String {
    case get = "GET"
    case post = "POST"
}

public struct Endpoint<Request: RequestEncoder, Response: ParsableResponse> {
    public var method: EndpointMethod
    public var path: String?
    
    public init(_ method: EndpointMethod, _ path: String?) {
        self.method = method
        self.path = path
    }
}

open class HTTPAPI {
    public let baseURL: URL
    let session = URLSession.shared
    
    public init(baseURL: URL) {
        self.baseURL = baseURL
    }
    
    public func request<E: RequestEncoder, P: ParsableResponse>(for endpoint: Endpoint<E, P>, with data: E?=nil) -> URLRequest {
        var url = baseURL
        
        if let path = endpoint.path {
            guard let urlWithPath = URL(string: path, relativeTo: baseURL) else {
                fatalError("invalid path \(path)")
            }
            url = urlWithPath
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        
        if let data = data {
            request = data.encode(request: request)
        }
        
        return request
    }
    
    @discardableResult public func start<P: ParsableResponse>(request: URLRequest, responseType: P.Type, completion: @escaping (Result<P>)->()) -> URLSessionDataTask {
        let task = session.dataTask(with: request) { data, response, error in
            var result = Result<P>(response: response as? HTTPURLResponse)
            
            if let error = error {
                result.error = error
            } else if let response = result.response {
                if let error = self.validate(response: response) {
                    result.error = error
                } else {
                    //TODO: use response encoding, if present
                    let encoding: String.Encoding = .utf8
                    
                    do {
                        result.value = try P.parse(responseData: data, encoding: encoding)
                    } catch {
                        result.error = error
                    }
                }
            }
            
            completion(result)
        }
        task.resume()
        
        return task
    }
    
    @discardableResult public func start<E: RequestEncoder, P: ParsableResponse>(request: URLRequest, for endpoint: Endpoint<E, P>, completion: @escaping (Result<P>)->()) -> URLSessionDataTask {
        return start(request: request, responseType: P.self, completion: completion)
    }
    
    @discardableResult public func call<E: RequestEncoder, P: ParsableResponse>(endpoint: Endpoint<E, P>, with data: E?=nil, completion: @escaping (Result<P>)->()) -> URLSessionDataTask {
        let request = self.request(for: endpoint, with: data)
        
        return start(request: request, for: endpoint, completion: completion)
    }
    
    private let acceptableStatusCodes = 200..<300
    
    open func validate(response: HTTPURLResponse) -> Error? {
        let code = response.statusCode
        if !acceptableStatusCodes.contains(code) {
            return APIError.unacceptableStatus(code: code)
        }
        
        return nil
    }
}
