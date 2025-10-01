// Copyright © 2023 DIAMIR. All Rights Reserved.

import Foundation

/// A type responsible for encoding and parsing all calls for a given Web API.
/// A basic implementation is provided by `AnyClient`.
public protocol Client: ResponseValidator, Sendable {
    var client: Client { get }
    
    /// Converts a `Call` created for this client's Web API
    /// into a `URLRequest`.
    func encode<C: Call>(call: C) async throws -> URLRequest

    /// Converts the `URLSession`s result for a `Call` to
    /// this client's Web API into the expected output type.
    ///
    /// - throws: Any `Error` if `result` is considered invalid.
    func parse<C: Call>(
        response: HTTPURLResponse?,
        data: Data?,
        for call: C
    ) async throws -> C.Parser.OutputType
}

public extension Client {
    /// Converts a `Call` created for this client's Web API
    /// into a `URLRequest`.
    func encode<C: Call>(call: C) async throws -> URLRequest {
        try await client.encode(call: call)
    }

    /// Converts the `URLSession`s result for a `Call` to
    /// this client's Web API into the expected output type.
    ///
    /// - throws: Any `Error` if `result` is considered invalid.
    func parse<C: Call>(
        response: HTTPURLResponse?,
        data: Data?,
        for call: C
    ) async throws -> C.Parser.OutputType {
        try await client.parse(response: response, data: data, for: call)
    }
    
    func validate(
        response: HTTPURLResponse?,
        data: Data?
    ) async throws {
        try await client.validate(response: response, data: data)
    }
}
