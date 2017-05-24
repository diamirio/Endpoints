import Foundation

/// A type representing a call to a Web API endpoint.
///
/// Encapsulates the request that is sent to the server and the type that is
/// expected in the response.
///
/// A `Client` uses `Call`s to encode requests and decode the server's response.
/// A `Session` can be used to start a `Call`.
/// 
/// You can implement this protocol to create a type-safe interface to your 
/// Web API:
/// ````
/// struct Login: Call {
///     typealias ResponseType = [String: Any] //you can use any ResponseDecodable
///
///     var user: String
///     var pwd: String
///
///     var request: URLRequestEncodable {
///         return Request(.post, "login", body: JSONEncodedBody(["user": user, "pwd": pwd]))
///     }
/// }
/// 
/// let login = Login(user: "user", pwd: "pwd")
/// ````
///
/// Alternatively, you can dynamically create `Call`s using `AnyCall`:
/// ````
/// let loginData = ["user": user, "pwd": pwd]
/// let login = AnyCall<[String: Any]>(Request(.post, "login", body: JSONEncodedBody(loginData)))
/// ````
///
/// Adopts `ResponseValidator`, so you can override `validate` if
/// you want to validate the response for a specific `Call` type. 
/// `AnyClient` will use this method to validate the response of the calls
/// request before using its `ResponseType` to decode it.
/// 
/// - seealso: `Client`, `Session`, `ResponseDecodable`, `Request`
public protocol Call: ResponseValidator {
    associatedtype ResponseType: ResponseDecodable
    
    var request: URLRequestEncodable { get }
}

public extension Call {
    
    /// No-Op. Override to perform call-specific validation
    func validate(result: URLSessionTaskResult) throws { /*no validation by default*/ }
}

/// Wraps an HTTP error code.
public enum StatusCodeError: Error {
    
    /// Describes an unacceptable status code for an HTTP request.
    /// Optionally, you can supply a `reason` which is then used as the 
    /// `errorDescription` instead of the default string returned by
    /// `HTTPURLResponse.localizedString(forStatusCode:)`
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

/// A type responsible for validating the result produced by a
/// `URLSession`s `completionHandler` block.
public protocol ResponseValidator {
    
    /// Validates the data provided by `URLSession`s `completionHandler`
    /// block.
    /// - throws: Any `Error`, if `result` is not valid.
    func validate(result: URLSessionTaskResult) throws
}

/// A type validating the status code of `HTTPURLResponse`.
public class StatusCodeValidator: ResponseValidator {
    
    /// Checks if an HTTP status code is acceptable
    /// - returns: `true` if `code` is between 200 and 299.
    public func isAcceptableStatus(code: Int) -> Bool {
        return (200..<300).contains(code)
    }
    
    /// - throws: `StatusCodeError.unacceptable` with `reason` set to `nil`
    /// if `result` contains an unacceptable status code.
    public func validate(result: URLSessionTaskResult) throws {
        if let code = result.httpResponse?.statusCode, !isAcceptableStatus(code: code) {
            throw StatusCodeError.unacceptable(code: code, reason: nil)
        }
    }
}

/// A type responsible for encoding and decoding all calls for a given Web API.
/// A basic implementation is provided by `AnyClient`.
public protocol Client {
    
    /// Converts a `Call` created for this client's Web API
    /// into a `URLRequest`.
    func encode<C: Call>(call: C) -> URLRequest
    
    /// Converts the `URLSession`s result for a `Call` to
    /// this client's Web API into the expected response type.
    ///
    /// - throws: Any `Error` if `result` is considered invalid.
    func decode<C: Call>(sessionTaskResult result: URLSessionTaskResult, for call: C) throws -> C.ResponseType
}

/// Encapsulates the result produced by a `URLSession`s
/// `completionHandler` block.
///
/// Mainly used by `Session` and `Client` to simplify the passing of 
/// parameters.
public struct URLSessionTaskResult {
    
    public var response: URLResponse?
    public var data: Data?
    public var error: Error?

    public init(response: URLResponse?=nil, data: Data?=nil, error: Error?=nil) {
       self.response = response
       self.data = data
       self.error = error
   }
    
    /// Returns `response` cast to `HTTPURLResponse`.
    public var httpResponse: HTTPURLResponse? {
        return response as? HTTPURLResponse
    }
}

/// The default implementation of `Client`.
///
/// All `Calls` made for a specific Web API should be encoded and decoded using
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
    public private(set) lazy var statusCodeValidator = StatusCodeValidator()
    
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
    /// Throws 'DecodingError.missingData` if `result.data` or `result.httpResponse` is `nil`.
    ///
    /// Finally tries to decode the response using `Call.ResponseType`
    /// and returns the decoded object or rethrows the resulting error.
    public func decode<C: Call>(sessionTaskResult result: URLSessionTaskResult, for call: C) throws -> C.ResponseType {
        if let error = result.error {
            throw error
        }
        
        try call.validate(result: result) //request-specific validation
        try validate(result: result) //global validation
        
        if let data = result.data, let response = result.httpResponse {
            return try C.ResponseType.responseDecoder()(response, data)
        } else {
            throw DecodingError.missingData
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
