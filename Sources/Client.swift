import Foundation

/// A type responsible for encoding and parsing all calls for a given Web API.
/// A basic implementation is provided by `AnyClient`.
public protocol Client {
    
    /// Converts a `Call` created for this client's Web API
    /// into a `URLRequest`.
    func encode<C: Call>(call: C) -> URLRequest
    
    /// Converts the `URLSession`s result for a `Call` to
    /// this client's Web API into the expected output type.
    ///
    /// - throws: Any `Error` if `result` is considered invalid.
    func parse<C: Call>(sessionTaskResult result: URLSessionTaskResult, for call: C) throws -> C.Parser.OutputType
}
