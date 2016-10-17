//
//  API.swift
//  Endpoint
//
//  Created by Peter W on 10/10/2016.
//  Copyright © 2016 Tailored Apps. All rights reserved.
//

import Foundation

public struct SessionTaskResult {
    var response: URLResponse?
    var data: Data?
    var error: Error?
    
    var httpResponse: HTTPURLResponse? {
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
    func validate(result: SessionTaskResult) throws
}

public class StatusCodeValidator: ResponseValidator {
    public func isAcceptableStatus(code: Int) -> Bool {
        return (200..<300).contains(code)
    }
    
    public func validate(result: SessionTaskResult) throws {
        if let code = result.httpResponse?.statusCode, !isAcceptableStatus(code: code) {
            throw StatusCodeError.unacceptable(code: code)
        }
    }
}

protocol Client {
    func encode<R: Request>(request: R) -> URLRequest
    func parse<P: ResponseParser>(sessionTaskResult result: SessionTaskResult, with parser: P.Type, validator: ResponseValidator?) throws -> P.OutputType
}

extension Client {
    var session: URLSession {
        return URLSession.shared
    }
    
    func transform<P: ResponseParser>(sessionResult: SessionTaskResult, with parser: P.Type, validator: ResponseValidator?=nil) -> Result<P.OutputType> {
        var result = Result<P.OutputType>(response: sessionResult.httpResponse)
        
        do {
            result.value = try self.parse(sessionTaskResult: sessionResult, with: parser.self, validator: validator)
        } catch {
            result.error = error
        }
        
        return result
    }
    
    @discardableResult
    func start<P: ResponseParser>(urlRequest: URLRequest, responseParser: P.Type, responseValidator: ResponseValidator?=nil, completion: @escaping (Result<P.OutputType>)->()) -> URLSessionDataTask {
        let task = session.dataTask(with: urlRequest) { data, response, error in
            let sessionResult = SessionTaskResult(response: response, data: data, error: error)
            let result = self.transform(sessionResult: sessionResult, with: responseParser, validator: responseValidator)
            
            completion(result)
        }
        task.resume()
        
        return task
    }
    
    @discardableResult
    func start<R: Request>(request: R, completion: @escaping (Result<R.ResponseType.OutputType>)->()) -> URLSessionDataTask {
        let urlRequest = encode(request: request)
        
        return start(urlRequest: urlRequest, responseParser: R.ResponseType.self, responseValidator: request, completion: completion)
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
    
    func parse<P: ResponseParser>(sessionTaskResult result: SessionTaskResult, with parser: P.Type, validator: ResponseValidator?=nil) throws -> P.OutputType {
        if let error = result.error {
            throw error
        }
        
        try validate(result: result) //global validation
        try validator?.validate(result: result) //request-specific validation
        
        if let data = result.data {
            return try parser.parse(responseData: data, encoding: .utf8) //TODO: use response encoding, if present
        } else {
            throw ParsingError.missingData
        }
    }
    
    public func validate(result: SessionTaskResult) throws {
        try statusCodeValidator.validate(result: result)
    }
}
