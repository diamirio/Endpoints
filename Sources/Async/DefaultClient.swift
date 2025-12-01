// Copyright © 2023 DIAMIR. All Rights Reserved.

import Foundation

public struct DefaultClient: Client {
    /// The base URL used by `encode` to convert `Call`s into `URLRequest`s.
    public let url: URL

    /// Used by `validate` to check if the status code of a response is valid.
    public let statusCodeValidator = StatusCodeValidator()

    /// Creates a client with a base URL.
    public init(url: URL) {
        self.url = url
    }

    public func encode(
        call: some Call
    ) async throws -> URLRequest {
        var urlRequest = call.request.urlRequest

        if let requestUrl = urlRequest.url, requestUrl.isRelative {
            urlRequest.url = URL(string: requestUrl.relativeString, relativeTo: url)
        }

        return urlRequest
    }

    public func parse<C>(
        response: HTTPURLResponse?,
        data: Data?,
        for call: C
    ) async throws -> C.Parser.OutputType where C: Call {
        guard let data, let response else {
            throw EndpointsParsingError.missingData
        }

        return try C.Parser().parse(response: response, data: data)
    }

    public func validate(
        response: HTTPURLResponse?,
        data: Data?
    ) async throws {
        try await statusCodeValidator.validate(response: response, data: data)
    }
}
