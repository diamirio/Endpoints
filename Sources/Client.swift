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
/// - seealso: `Client`, `Session`, `ResponseDecodable`, `Request`
public protocol Call {
    associatedtype ResponseType: ResponseDecodable = Data
    
    var request: URLRequestEncodable { get }

    /// Decode the result of a `URLSessionTask` for a request
    /// created by `self`.
    ///
    /// A default implementation is provided by `defaultDecode`.
    func decode(result: URLSessionTaskResult) throws -> ResponseType
}

public extension Call {
    /// Forwards to `defaultDecode`.
    func decode(result: URLSessionTaskResult) throws -> ResponseType {
        return try defaultDecode(result: result)
    }

    /// Throws `result.error` if not-nil.
    ///
    /// Throws 'DecodingError.missingData` if `result.data`
    /// or `result.httpResponse` is `nil`.
    ///
    /// Finally delegates decoding to the block returned by
    /// `ResponseType.responseDecoder()` and returns the decoded
    ///  object or rethrows a decoding error.
    final func defaultDecode(result: URLSessionTaskResult) throws -> ResponseType {
        if let error = result.error {
            throw error
        }

        guard let data = result.data, let response = result.httpResponse else {
            throw DecodingError.missingData
        }

        return try ResponseType.responseDecoder()(response, data)
    }
}

/// Wraps an HTTP error code.
public enum StatusCodeError: LocalizedError {
    
    /// Describes an unacceptable status code for an HTTP request.
    /// Optionally, you can supply a `reason` which is then used as the 
    /// `errorDescription` instead of the default string returned by
    /// `HTTPURLResponse.localizedString(forStatusCode:)`
    case unacceptable(code: Int, reason: String?)

    public var errorDescription: String? {
        switch self {
        case .unacceptable(let code, let reason):
            return reason ?? HTTPURLResponse.localizedString(forStatusCode: code)
        }
    }
}

public extension HTTPURLResponse {
    /// Checks if an HTTP status code is acceptable
    /// - returns: `true` if `code` is between 200 and 299.
    func hasAcceptableStatus() -> Bool {
        return (200..<300).contains(statusCode)
    }

    /// - throws: `StatusCodeError.unacceptable` with `reason` set to `nil`
    /// if `httpResponse` contains an unacceptable status code.
    func validateStatusCode() throws {
        guard hasAcceptableStatus() else {
            throw StatusCodeError.unacceptable(code: statusCode, reason: nil)
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
    func decode<C: Call>(result: URLSessionTaskResult, for call: C) throws -> C.ResponseType
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
}

public protocol URLResponseHolder {
    var response: URLResponse? { get }
}

extension URLResponseHolder {
    /// Returns `response` cast to `HTTPURLResponse`.
    public var httpResponse: HTTPURLResponse? {
        return response as? HTTPURLResponse
    }
}

extension URLSessionTaskResult: URLResponseHolder {}
extension URLSessionTask: URLResponseHolder {}

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
open class AnyClient: Client {
    
    /// The base URL used by `encode` to convert `Call`s into `URLRequest`s.
    public let baseURL: URL
    
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

    /// Validates if `result` is processable by this client using 
    /// `validate(result:)` and puts any thrown error into `result`.
    /// Then `call.decode(result:)` is used to decode `call`s response
    /// type. If this fails, the error is rethrown.
    public func decode<C: Call>(result: URLSessionTaskResult, for call: C) throws -> C.ResponseType {
        var result = result

        do {
            try validate(result: result)
        } catch {
            result.error = error
        }

        return try call.decode(result: result)
    }
    
    /// Validates the status code using `HTTPURLResponse.validateStatusCode()`.
    /// 
    /// Override to perform additional validation necessary for *all* calls
    /// related to this client.
    open func validate(result: URLSessionTaskResult) throws {
        try result.httpResponse?.validateStatusCode()
    }
}
