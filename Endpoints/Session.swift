//
//  Session.swift
//  Endpoints
//
//  Created by Peter W on 24/10/2016.
//  Copyright © 2016 Tailored Apps. All rights reserved.
//

import Foundation

public class Task<Value> {
    public typealias WhenDoneBlock = ()->()
    public typealias SuccessBlock = (Value)->()
    public typealias ErrorBlock = (Error)->()
    
    public internal(set) var urlSessionDataTask: URLSessionDataTask?
    
    internal private(set) var whenDoneBlock: WhenDoneBlock?
    internal private(set) var onSuccessBlock: SuccessBlock?
    internal private(set) var onErrorBlock: ErrorBlock?
    
    public var httpResponse: HTTPURLResponse? {
        return urlSessionDataTask?.response as? HTTPURLResponse
    }
    
    public var statusCode: Int? {
        return httpResponse?.statusCode
    }
    
    @discardableResult
    public func whenDone(block: @escaping WhenDoneBlock) -> Self {
        assert(urlSessionDataTask != nil)
        self.whenDoneBlock = block
        
        return self
    }
    
    @discardableResult
    public func onSuccess(block: @escaping SuccessBlock) -> Self {
        assert(urlSessionDataTask != nil)
        self.onSuccessBlock = block
        
        return self
    }
    
    @discardableResult
    public func onError(block: @escaping ErrorBlock) -> Self {
        assert(urlSessionDataTask != nil)
        self.onErrorBlock = block
        
        return self
    }
}

public class Session<C: Client> {
    public var debug = false
    
    public var urlSession: URLSession
    public var completionQueue: DispatchQueue
    public let client: C
    
    public init(with client: C, using urlSession: URLSession=URLSession.shared, completionQueue: DispatchQueue=DispatchQueue.main) {
        self.client = client
        self.urlSession = urlSession
        self.completionQueue = completionQueue
    }
    
    public func start<R: Request>(request: R) -> Task<R.ResponseType.OutputType> {
        let urlRequest = client.encode(request: request)
        let task = Task<R.ResponseType.OutputType>()
        
        task.urlSessionDataTask = urlSession.dataTask(with: urlRequest) { data, response, error in
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

            do {
                let value = try self.client.parse(sessionTaskResult: sessionResult, for: request)
                
                self.complete { task.onSuccessBlock?(value) }
            } catch {
                self.complete { task.onErrorBlock?(error) }
            }
            
            self.complete { task.whenDoneBlock?() }
        }
        task.urlSessionDataTask!.resume()
        
        return task
    }
    
    func complete(_ block: @escaping ()->()) {
        self.completionQueue.async(execute: block)
    }
}
