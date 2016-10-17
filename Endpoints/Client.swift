//
//  API.swift
//  Endpoint
//
//  Created by Peter W on 10/10/2016.
//  Copyright © 2016 Tailored Apps. All rights reserved.
//

import Foundation

public struct SessionTaskResult {
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
    func validate(result: SessionTaskResult) throws
}

public class StatusCodeValidator: ResponseValidator {
    public func isAcceptableStatus(code: Int) -> Bool {
        return (200..<300).contains(code)
    }
    
    public func validate(result: SessionTaskResult) throws {
        if let code = result.httpResponse?.statusCode, !isAcceptableStatus(code: code) {
            throw StatusCodeError.unacceptable(code: code, reason: nil)
        }
    }
}

public protocol Client {
    func encode<R: Request>(request: R) -> URLRequest
    func parse<R: Request>(sessionTaskResult result: SessionTaskResult, for request: R) throws -> R.ResponseType.OutputType
}

public extension Client {
    public var session: URLSession {
        return URLSession.shared
    }
    
    public func transform<R: Request>(sessionResult: SessionTaskResult, for request: R) -> Result<R.ResponseType.OutputType> {
        var result = Result<R.ResponseType.OutputType>(response: sessionResult.httpResponse)
        
        do {
            result.value = try self.parse(sessionTaskResult: sessionResult, for: request)
        } catch {
            result.error = error
        }
        
        return result
    }
    
    @discardableResult
    public func start<R: Request>(request: R, completion: @escaping (Result<R.ResponseType.OutputType>)->()) -> URLSessionDataTask {
        let urlRequest = encode(request: request)
        
        let task = session.dataTask(with: urlRequest) { data, response, error in
            let sessionResult = SessionTaskResult(response: response, data: data, error: error)
            let result = self.transform(sessionResult: sessionResult, for: request)
            
            completion(result)
        }
        task.resume()
        
        return task
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
    
    open func encode<R: Request>(request: R) -> URLRequest {
        return request.encode(withBaseURL: baseURL)
    }
    
    public func parse<R: Request>(sessionTaskResult result: SessionTaskResult, for request: R) throws -> R.ResponseType.OutputType {
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
    
    open func validate<R: Request>(result: SessionTaskResult, for request: R) throws {
        try validate(result: result) //global validation
        try request.validate(result: result) //request-specific validation
    }
    
    open func validate(result: SessionTaskResult) throws {
        try statusCodeValidator.validate(result: result)
    }
}
