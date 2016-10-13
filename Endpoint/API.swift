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

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

public protocol Endpoint {
    associatedtype Request: RequestEncoder
    associatedtype Response: ParsableResponse
    
    var method: HTTPMethod { get }
    var path: String? { get }
}

public protocol EndpointRequest: Endpoint, RequestData { }

public struct DynamicEndpoint<Input: RequestEncoder, Output: ParsableResponse>: Endpoint {
    public typealias Request = Input
    public typealias Response = Output
    
    public var method: HTTPMethod
    public var path: String?
    
    public init(_ method: HTTPMethod, _ path: String?) {
        self.method = method
        self.path = path
    }
}

open class API {
    public let baseURL: URL
    let session = URLSession.shared
    
    public init(baseURL: URL) {
        self.baseURL = baseURL
    }
    
    public func request<E: Endpoint, R: RequestEncoder>(for endpoint: E, with data: R?=nil) -> URLRequest where E.Request == R {
        var url = baseURL
        
        if let path = endpoint.path {
            guard let urlWithPath = URL(string: path, relativeTo: baseURL) else {
                fatalError("invalid path \(path)")
            }
            url = urlWithPath
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        
        if let data = data ?? endpoint as? R {
            request = data.encode(request: request)
        }
        
        return request
    }
    
    @discardableResult public func start<P: ParsableResponse>(request: URLRequest, responseType: P.Type, debug: Bool=false, completion: @escaping (Result<P>)->()) -> URLSessionDataTask {
        let task = session.dataTask(with: request) { data, response, error in
            if debug {
                dump(request)
            }
            
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
    
    @discardableResult public func start<E: Endpoint, P: ParsableResponse>(request: URLRequest, for endpoint: E, debug: Bool=false, completion: @escaping (Result<P>)->()) -> URLSessionDataTask where E.Response == P {
        return start(request: request, responseType: P.self, debug: debug, completion: completion)
    }
    
    @discardableResult public func call<E: Endpoint, R: RequestEncoder, P: ParsableResponse>(endpoint: E, with data: R?=nil, debug: Bool=false, completion: @escaping (Result<P>)->()) -> URLSessionDataTask where E.Request == R, E.Response == P {
        let request = self.request(for: endpoint, with: data)
        
        return start(request: request, for: endpoint, debug: debug, completion: completion)
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

extension API {
    
}
