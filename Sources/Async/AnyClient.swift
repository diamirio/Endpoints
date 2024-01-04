// Copyright © 2023 DIAMIR. All Rights Reserved.

import Foundation

open class AnyClient: Client {
    /// The base URL used by `encode` to convert `Call`s into `URLRequest`s.
    public let baseURL: URL

    /// Used by `validate` to check if the status code of a response is valid.
    public let statusCodeValidator = StatusCodeValidator()

    /// Creates a client with a base URL.
    public init(baseURL: URL) {
        self.baseURL = baseURL
    }

    open func encode(
        call: some Call
    ) async throws -> URLRequest {
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
    ) async throws -> C.Parser.OutputType where C: Call {
        guard let data, let response else {
            throw EndpointsParsingError.missingData
        }

        return try C.Parser().parse(response: response, data: data)
    }

    open func validate(
        response: HTTPURLResponse?,
        data: Data?
    ) async throws {
        try statusCodeValidator.validate(response: response, data: data)
    }
}
