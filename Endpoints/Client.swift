//
//  API.swift
//  Endpoint
//
//  Created by Peter W on 10/10/2016.
//  Copyright © 2016 Tailored Apps. All rights reserved.
//

import Foundation

public struct Result<Value> {
    public private(set) var value: Value?
    public private(set) var error: Error?
    
    public let response: HTTPURLResponse?
    
    public var isSuccess: Bool { return !isError }
    public var isError: Bool { return error != nil }
    
    init<P: ResponseParser>(response: URLResponse?, data: Data?, error: Error?, parser: P.Type, validator: ResponseValidator?=nil) where P.OutputType == Value {
        self.response = response as? HTTPURLResponse
        
        if let error = error {
            self.error = error
        } else if let response = self.response {
            if let error = validator?.validate(response: response) {
                self.error = error
            } else {
                //TODO: use response encoding, if present
                let encoding: String.Encoding = .utf8
                
                do {
                    value = try parser.parse(responseData: data, encoding: encoding)
                } catch {
                    self.error = error
                }
            }
        }
    }
}

public enum StatusCodeError: Error {
    case unacceptable(code: Int)
}

extension StatusCodeError {
    public var localizedDescription: String {
        switch  self {
        case .unacceptable(let code):
            return HTTPURLResponse.localizedString(forStatusCode: code)
        }
    }
}

public protocol ResponseValidator {
    func validate(response: HTTPURLResponse) -> Error?
}

public class StatusCodeValidator: ResponseValidator {
    public func isAcceptableStatus(code: Int) -> Bool {
        return (200..<300).contains(code)
    }
    
    public func validate(response: HTTPURLResponse) -> Error? {
        let code = response.statusCode
        
        if !isAcceptableStatus(code: code) {
            return StatusCodeError.unacceptable(code: code)
        }
        
        return nil
    }
}

protocol Client {
    func encode<R: Request>(request: R) -> URLRequest
    func transform<P: ResponseParser>(response: URLResponse?, data: Data?, error: Error?, parser: P.Type) -> Result<P.OutputType>
}

extension Client {
    var session: URLSession {
        return URLSession.shared
    }
    
    @discardableResult
    func start<P: ResponseParser>(urlRequest: URLRequest, responseParser: P.Type, completion: @escaping (Result<P.OutputType>)->()) -> URLSessionDataTask {
        let task = session.dataTask(with: urlRequest) { data, response, error in
            let result = self.transform(response: response, data: data, error: error, parser: responseParser.self)
            
            completion(result)
        }
        task.resume()
        
        return task
    }
    
    @discardableResult
    func start<R: Request>(request: R, completion: @escaping (Result<R.ResponseType.OutputType>)->()) -> URLSessionDataTask {
        let urlRequest = encode(request: request)
        
        return start(urlRequest: urlRequest, responseParser: R.ResponseType.self, completion: completion)
    }
}

open class BaseClient: Client, ResponseValidator {
    public let baseURL: URL
    public let session: URLSession
    public lazy var statusCodeValidator = StatusCodeValidator()
    //TODO: implement debugging
    public var debug = false
    
    public init(baseURL: URL, session: URLSession=URLSession.shared) {
        self.baseURL = baseURL
        self.session = session
    }
    
    func encode<R: Request>(request: R) -> URLRequest {
        return request.encode(withBaseURL: baseURL)
    }
    
    func transform<P: ResponseParser>(response: URLResponse?, data: Data?, error: Error?, parser: P.Type) -> Result<P.OutputType> {
        return Result<P.OutputType>(response: response, data: data, error: error, parser: parser, validator: self)
    }
    
    public func validate(response: HTTPURLResponse) -> Error? {
        return statusCodeValidator.validate(response: response)
    }
}
