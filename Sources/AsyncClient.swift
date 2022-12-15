//
//  AsyncClient.swift
//  
//
//  Created by Dominik Arnhof on 06.12.22.
//

import Foundation

#if compiler(>=5.5) && canImport(_Concurrency)

/// A type responsible for encoding and parsing all calls for a given Web API.
/// A basic implementation is provided by `AnyClient`.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0,  *)
public protocol AsyncClient {
    
    /// Converts a `Call` created for this client's Web API
    /// into a `URLRequest`.
    func encode<C: Call>(call: C) async throws -> URLRequest
    
    /// Converts the `URLSession`s result for a `Call` to
    /// this client's Web API into the expected output type.
    ///
    /// - throws: Any `Error` if `result` is considered invalid.
    func parse<C: Call>(sessionTaskResult result: URLSessionTaskResult, for call: C) async throws -> C.Parser.OutputType
}

#endif
