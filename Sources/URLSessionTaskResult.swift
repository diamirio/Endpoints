import Foundation

/// Encapsulates the result produced by a `URLSession`s
/// `completionHandler` block.
///
/// Mainly used by `Session` and `Client` to simplify the passing of
/// parameters.
public struct URLSessionTaskResult {

    public var response: URLResponse?
    public var data: Data?
    public var error: Error?

    public init(response: URLResponse? = nil, data: Data? = nil, error: Error? = nil) {
       self.response = response
       self.data = data
       self.error = error
   }

    /// Returns `response` cast to `HTTPURLResponse`.
    public var httpResponse: HTTPURLResponse? {
        return response as? HTTPURLResponse
    }
}
