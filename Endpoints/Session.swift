//
//  Session.swift
//  Endpoints
//
//  Created by Peter W on 24/10/2016.
//  Copyright © 2016 Tailored Apps. All rights reserved.
//

import Foundation

public struct Result<Value> {
    public var value: Value?
    public var error: Error?
    
    public let response: HTTPURLResponse?
    
    public init(response: HTTPURLResponse?) {
        self.response = response
    }
    
    public func onSuccess(block: (Value)->()) -> Result {
        if let value = value {
            block(value)
        }
        return self
    }
    
    public func onError(block: (Error)->()) -> Result {
        if let error = error {
            block(error)
        }
        return self
    }
}

public class Session<C: Client> {
    public var debug = false
    
    public var urlSession: URLSession
    public let client: C
    
    public init(with client: C, using urlSession: URLSession=URLSession.shared) {
        self.client = client
        self.urlSession = urlSession
    }
    
    @discardableResult
    public func start<R: Request>(request: R, completion: @escaping (Result<R.ResponseType.OutputType>)->()) -> URLSessionDataTask {
        let urlRequest = client.encode(request: request)
        
        let task = urlSession.dataTask(with: urlRequest) { data, response, error in
            let sessionResult = URLSessionTaskResult(response: response, data: data, error: error)
            
            if self.debug {
                let status = sessionResult.httpResponse?.statusCode
                if let data = data, let string = String(data: data, encoding: String.Encoding.utf8) {
                    let str = string as NSString
                    print("response string for \(urlRequest) with status: \(status):\n\(str)")
                } else {
                    print("no response string for \(urlRequest). error: \(error). status: \(status)")
                }
            }
            
            let result = self.transform(sessionResult: sessionResult, for: request)
            
            DispatchQueue.main.async {
                completion(result)
            }
        }
        task.resume()
        
        return task
    }
    
    public final func transform<R: Request>(sessionResult: URLSessionTaskResult, for request: R) -> Result<R.ResponseType.OutputType> {
        var result = Result<R.ResponseType.OutputType>(response: sessionResult.httpResponse)
        
        do {
            result.value = try client.parse(sessionTaskResult: sessionResult, for: request)
        } catch {
            result.error = error
        }
        
        return result
    }
}
