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

public enum StatusCodeError: Error {
    case unacceptable(code: Int, reason: String?)
}

extension StatusCodeError: LocalizedError {
    public var errorDescription: String? {
        switch self {
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
