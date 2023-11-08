//
//  AnyAsyncClient.swift
//  
//
//  Created by Dominik Arnhof on 06.12.22.
//

import Foundation

#if compiler(>=5.5) && canImport(_Concurrency)

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0,  *)
open class AnyAsyncClient: AsyncClient, ResponseValidator {
    /// The base URL used by `encode` to convert `Call`s into `URLRequest`s.
    public let baseURL: URL

    /// Used by `validate` to check if the status code of a response is valid.
    public let statusCodeValidator = StatusCodeValidator()

    /// Creates a client with a base URL.
    public init(baseURL: URL) {
        self.baseURL = baseURL
    }
    
    open func encode<C>(call: C) async throws -> URLRequest where C : Call {
        var urlRequest = call.request.urlRequest

        if let url = urlRequest.url, url.isRelative {
            urlRequest.url = URL(string: url.relativeString, relativeTo: baseURL)
        }

        return urlRequest
    }
    
    open func parse<C>(sessionTaskResult result: URLSessionTaskResult, for call: C) async throws -> C.Parser.OutputType where C : Call {
        if let error = result.error {
            throw error
        }

        try call.validate(result: result) // request-specific validation
        try validate(result: result) //global validation

        if let data = result.data, let response = result.httpResponse {
            return try C.Parser().parse(response: response, data: data)
        } else {
            throw EndpointsParsingError.missingData
        }
    }
    
    open func validate(result: URLSessionTaskResult) throws {
        try statusCodeValidator.validate(result: result)
    }
}

#endif
