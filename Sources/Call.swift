import Foundation

/// A type representing a call to a Web API endpoint.
///
/// Encapsulates the request that is sent to the server and the type that is
/// expected in the response.
///
/// A `Client` uses `Call`s to encode requests and parse the server's response.
/// A `Session` can be used to start a `Call`.
///
/// You can implement this protocol to create a type-safe interface to your
/// Web API:
/// ````
/// struct Login: Call {
///     typealias Parser = DictionaryParser<String, Any> //you can use any ResponseParser
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
/// let login = AnyCall<DictionaryParser<String, Any>>(Request(.post, "login", body: JSONEncodedBody(loginData)))
/// ````
///
/// Adopts `ResponseValidator`, so you can override `validate` if
/// you want to validate the response for a specific `Call` type.
/// `AnyClient` will use this method to validate the response of the calls
/// request before using its `Parser` to parse it.
///
/// - seealso: `Client`, `Session`, `DataParser`, `Request`
public protocol Call: ResponseValidator {
    associatedtype Parser: ResponseParser

    var request: URLRequestEncodable { get }
}

public extension Call {

    /// No-Op. Override to perform call-specific validation
    func validate(result: URLSessionTaskResult) throws { /*no validation by default*/ }
}
