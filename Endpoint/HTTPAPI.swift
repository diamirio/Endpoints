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

public protocol RequestEncoder {
    func encode(request: URLRequest) -> URLRequest
}

public struct RequestData: RequestEncoder {
    public typealias Parameters = [String: String]
    
    public var path: String?
    public var query: Parameters?
    public var header: Parameters?
    public var body: Data?
    
    public init(path: String?=nil, query: Parameters?=nil, headers: Parameters?=nil, body: Data?=nil) {
        self.path = path
        self.query = query
        self.header = headers
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
        
        if let dynamicPath = path {
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

public protocol ResponseType {
    static func parse(responseData: Data?, encoding: String.Encoding) throws -> Self?
}

extension ResponseType {
    static func parseJSON(responseData: Data?) throws -> Any {
        return try JSONSerialization.jsonObject(with: responseData ?? Data(), options: .allowFragments)
    }
}

extension Data: ResponseType {
    public static func parse(responseData: Data?, encoding: String.Encoding) throws -> Data? {
        return responseData
    }
}

extension String: ResponseType {
    public static func parse(responseData: Data?, encoding: String.Encoding) throws -> String? {
        guard let data = responseData else {
            return nil
        }
        
        if let string = String(data: data, encoding: encoding) {
            return string
        } else {
            throw APIError.parsingError(description: "String could not be parsed with encoding: \(encoding)")
        }
    }
}

extension Dictionary: ResponseType {
    public static func parse(responseData: Data?, encoding: String.Encoding) throws -> Dictionary? {
        guard let dict = try parseJSON(responseData: responseData) as? Dictionary else {
            throw APIError.parsingError(description: "JSON structure is not an Object")
        }
        
        return dict
    }
}

extension Array: ResponseType {
    public static func parse(responseData: Data?, encoding: String.Encoding) throws -> Array? {
        guard let array = try parseJSON(responseData: responseData) as? Array else {
            throw APIError.parsingError(description: "JSON structure is not an Array")
        }
        
        return array
    }
}

public struct Result<Value: ResponseType> {
    public fileprivate(set) var value: Value?
    public fileprivate(set) var error: Error?
    
    public fileprivate(set) var response: HTTPURLResponse?
    
    public var isSuccess: Bool {
        return !isError
    }
    
    public var isError: Bool {
        return error != nil
    }
    
    fileprivate init(response: HTTPURLResponse?) {
        self.response = response
    }
}

public enum EndpointMethod: String {
    case get = "GET"
    case post = "POST"
}

public struct Endpoint<E: RequestEncoder, P: ResponseType> {
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
    
    public func request<E: RequestEncoder, P: ResponseType>(for endpoint: Endpoint<E, P>, with data: E?=nil) -> URLRequest {
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
    
    @discardableResult public func start<P: ResponseType>(request: URLRequest, responseType: P.Type, completion: @escaping (Result<P>)->()) -> URLSessionDataTask {
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
    
    @discardableResult public func start<E: RequestEncoder, P: ResponseType>(request: URLRequest, for endpoint: Endpoint<E, P>, completion: @escaping (Result<P>)->()) -> URLSessionDataTask {
        return start(request: request, responseType: P.self, completion: completion)
    }
    
    @discardableResult public func call<E: RequestEncoder, P: ResponseType>(endpoint: Endpoint<E, P>, with data: E?=nil, completion: @escaping (Result<P>)->()) -> URLSessionDataTask {
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
