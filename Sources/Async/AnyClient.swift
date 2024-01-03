// Copyright © 2023 DIAMIR. All Rights Reserved.

import Foundation

open class AnyClient: Client, ResponseValidator {
    
    /// The base URL used by `encode` to convert `Call`s into `URLRequest`s.
    public let baseURL: URL

    /// Used by `validate` to check if the status code of a response is valid.
    public let statusCodeValidator = StatusCodeValidator()

    /// Creates a client with a base URL.
    public init(baseURL: URL) {
        self.baseURL = baseURL
    }
    
    open func encode<C>(
        call: C
    ) async throws -> URLRequest where C : Call {
        var urlRequest = call.request.urlRequest

        if let url = urlRequest.url, url.isRelative {
            urlRequest.url = URL(string: url.relativeString, relativeTo: baseURL)
        }

        return urlRequest
    }
    
    open func parse<C>(
        response: HTTPURLResponse?,
        data: Data?,
        for call: C
    ) async throws -> C.Parser.OutputType where C : Call {
        try call.validate(response: response, data: data) // request-specific validation
        try validate(response: response, data: data) //global validation

        guard let data, let response else {
            throw EndpointsParsingError.missingData
        }

        return try C.Parser().parse(response: response, data: data)
    }
    
    open func validate(
        response: HTTPURLResponse?,
        data: Data?
    ) throws {
        try statusCodeValidator.validate(response: response, data: data)
    }
}
