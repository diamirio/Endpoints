//
//  API.swift
//  Endpoint
//
//  Created by Peter W on 10/10/2016.
//  Copyright © 2016 Tailored Apps. All rights reserved.
//

import Foundation

public struct URLSessionTaskResult {
    public var response: URLResponse?
    public var data: Data?
    public var error: Error?
    
    public var httpResponse: HTTPURLResponse? {
        return response as? HTTPURLResponse
    }
}

public struct Result<Value> {
    public internal(set) var value: Value?
    public internal(set) var error: Error?
    
    public let response: HTTPURLResponse?
    
    public var isSuccess: Bool { return !isError }
    public var isError: Bool { return error != nil }
    
    init(response: HTTPURLResponse?) {
        self.response = response
    }
}

public enum StatusCodeError: Error {
    case unacceptable(code: Int, reason: String?)
}

extension StatusCodeError {
    public var localizedDescription: String {
        switch  self {
        case .unacceptable(let code, let reason):
            return reason ?? HTTPURLResponse.localizedString(forStatusCode: code)
        }
    }
}

public protocol ResponseValidator {
    func validate(result: URLSessionTaskResult) throws
}

public class StatusCodeValidator: ResponseValidator {
    public func isAcceptableStatus(code: Int) -> Bool {
        return (200..<300).contains(code)
    }
    
    public func validate(result: URLSessionTaskResult) throws {
        if let code = result.httpResponse?.statusCode, !isAcceptableStatus(code: code) {
            throw StatusCodeError.unacceptable(code: code, reason: nil)
        }
    }
}

public protocol Client {
    func encode<R: Request>(request: R) -> URLRequest
    func parse<R: Request>(sessionTaskResult result: URLSessionTaskResult, for request: R) throws -> R.ResponseType.OutputType
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

open class BaseClient: Client, ResponseValidator {
    public let baseURL: URL
    public private(set) lazy var statusCodeValidator = StatusCodeValidator()
    
    public init(baseURL: URL) {
        self.baseURL = baseURL
    }
    
    open func encode<R: Request>(request: R) -> URLRequest {
        return request.encode(withBaseURL: baseURL)
    }
    
    public func parse<R: Request>(sessionTaskResult result: URLSessionTaskResult, for request: R) throws -> R.ResponseType.OutputType {
        if let error = result.error {
            throw error
        }
        
        try validate(result: result, for: request)
        
        if let data = result.data {
            return try R.ResponseType.self.parse(responseData: data, encoding: .utf8) //TODO: use response encoding, if present
        } else {
            throw ParsingError.missingData
        }
    }
    
    public func validate<R: Request>(result: URLSessionTaskResult, for request: R) throws {
        try validate(result: result) //global validation
        try request.validate(result: result) //request-specific validation
    }
    
    open func validate(result: URLSessionTaskResult) throws {
        try statusCodeValidator.validate(result: result)
    }
}
