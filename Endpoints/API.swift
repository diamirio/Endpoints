//
//  API.swift
//  Endpoint
//
//  Created by Peter W on 10/10/2016.
//  Copyright © 2016 Tailored Apps. All rights reserved.
//

import Foundation

public enum APIError: Error {
    case unacceptableStatus(code: Int, description: String)
    case parsingError(description: String)
    case serverError(description: String)
}

open class API {
    public let baseURL: URL
    public var debugAll = false
    
    public init(baseURL: URL) {
        self.baseURL = baseURL
    }
    
    public func request<E: Endpoint, R: RequestEncoder>(for endpoint: E, with data: R?=nil) -> URLRequest where E.RequestType == R {
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
    
    public func transform<P: ResponseParser>(response: URLResponse?, for request: URLRequest, with data: Data?, error: Error?, debug: Bool, parser: P.Type) -> Result<P.OutputType> {
        var result = Result<P.OutputType>(response: response as? HTTPURLResponse)
        
        if debug || debugAll {
            if let data = data, let string = String(data: data, encoding: .utf8) {
                debugPrint("response string for \(request) with status: \(result.response?.statusCode):\n\(string)")
            } else {
                debugPrint("no response string for \(request). error: \(result.error). status: \(result.response?.statusCode)")
            }
        }
        
        if let error = error {
            result.error = error
        } else if let response = result.response {
            if let error = self.validate(response: response) {
                result.error = error
            } else {
                //TODO: use response encoding, if present
                let encoding: String.Encoding = .utf8
                
                do {
                    result.value = try parser.parse(responseData: data, encoding: encoding)
                } catch {
                    result.error = error
                }
            }
        }
        
        return result
    }
    
    open func validate(response: HTTPURLResponse) -> Error? {
        let code = response.statusCode
        
        if !(200..<300).contains(code) {
            var message = response.allHeaderFields["X-Error-Message"] as? String
            message = message?.removingPercentEncoding
            
            if message == nil {
                message = HTTPURLResponse.localizedString(forStatusCode: code)
            }
            
            return APIError.unacceptableStatus(code: code, description: message!)
        }

        return nil
    }
    
    @discardableResult
    public func call<E: Endpoint, P: ResponseParser>(endpoint: E, with data: E.RequestType?=nil, session: URLSession=URLSession.shared, debug: Bool=false, completion: @escaping (Result<P.OutputType>)->()) -> URLSessionDataTask where E.ResponseType == P {
        let request = self.request(for: endpoint, with: data)
        
        return start(request: request, for: endpoint, session: session, debug: debug, completion: completion)
    }
    
    @discardableResult
    public func start<E: Endpoint, P: ResponseParser>(request: URLRequest, for endpoint: E, session: URLSession=URLSession.shared, debug: Bool=false, completion: @escaping (Result<P.OutputType>)->()) -> URLSessionDataTask where E.ResponseType == P {
        return start(request: request, responseType: P.self, session: session, debug: debug, completion: completion)
    }
    
    @discardableResult
    public func start<P: ResponseParser>(request: URLRequest, responseType: P.Type, session: URLSession=URLSession.shared, debug: Bool=false, completion: @escaping (Result<P.OutputType>)->()) -> URLSessionDataTask {
        let task = session.dataTask(with: request) { data, response, error in
            let result = self.transform(response: response, for: request, with: data, error: error, debug: debug, parser: responseType)
            
            completion(result)
        }
        task.resume()
        
        return task
    }
}
