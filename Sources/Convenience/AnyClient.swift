import Foundation

/// The default implementation of `Client`.
///
/// All `Calls` made for a specific Web API should be encoded and parsed using
/// a dedicated `Client` type.
///
/// You typically create a subclass of `AnyClient` for each Web API you want
/// to access from your App.
///
/// Override `encode` to supply additional parameters to requests
/// required for the client's Web API.
///
/// Override `validate` to perform validation necessary for the client's Web
/// API.
///
/// Use a `Session` configured with a `Client` to start `Call`s using a
/// `URLSession`.
open class AnyClient: Client, ResponseValidator {

    /// The base URL used by `encode` to convert `Call`s into `URLRequest`s.
    public let baseURL: URL

    /// Used by `validate` to check if the status code of a response is valid.
    public let statusCodeValidator = StatusCodeValidator()

    /// Creates a client with a base URL.
    public init(baseURL: URL) {
        self.baseURL = baseURL
    }

    /// Returns `call.urlRequest`, if its URL is absolute.
    ///
    /// If `call.urlRequest.url` is relative, the `URLRequest` will be
    /// using this client's `baseURL` combined with `call`s relative URL.
    ///
    /// Override to supply additional parameters to all requests
    /// encoded by this client.
    /// Use `Call.urlRequest` for call-specific encoding.
    open func encode<C: Call>(call: C) -> URLRequest {
        var urlRequest = call.request.urlRequest

        if let url = urlRequest.url, url.isRelative {
            urlRequest.url = URL(string: url.relativeString, relativeTo: baseURL)
        }

        return urlRequest
    }

    /// Throws `result.error`, if it is not `nil`.
    ///
    /// Validates if `result` is processable by this client using
    /// `validate(result:)` and rethrows the resulting error, if any.
    ///
    /// Uses `call`s `validate` method to perform call-specific validation
    /// and rethrows the resulting error, if any.
    ///
    /// Throws 'ParsingError.missingData` if `result.data` or `result.httpResponse` is `nil`.
    ///
    /// Finally tries to parse the response using `Call.Parser`
    /// and returns the parsed object or rethrows the resulting error.
    public func parse<C: Call>(sessionTaskResult result: URLSessionTaskResult, for call: C) throws -> C.Parser.OutputType {
        if let error = result.error {
            throw error
        }

        try call.validate(result: result) //request-specific validation
        try validate(result: result) //global validation

        if let data = result.data, let response = result.httpResponse {
            return try C.Parser().parse(response: response, data: data)
        } else {
            throw ParsingError.missingData
        }
    }

    /// Uses `StatusCodeValidator` to validate `result`.
    ///
    /// Override to perform additional validation necessary for *all* calls
    /// related to this client.
    /// Use `Call.validate` for call-specific validation.
    open func validate(result: URLSessionTaskResult) throws {
        try statusCodeValidator.validate(result: result)
    }
}
