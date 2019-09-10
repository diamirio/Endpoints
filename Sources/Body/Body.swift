import Foundation

/// A type representing an HTTP Body.
///
/// A `Body` is used by `Request` to create an `URLRequest`.
///
/// Adopted by `Data` and `String`.
/// - seealso: `FormEncodedBody`, `JSONEncodedBody`.
public protocol Body {

    /// Returns HTTP Header parameters required for `self`, if any.
    ///
    /// This is usally a "Content-Type" header like "application/json" for a
    /// JSON encoded Body.
    ///
    /// Defaults to `nil`.
    var header: Parameters? { get }

    /// The body data that should be sent in an HTTP request.
    var requestData: Data { get }
}

extension Body {
    public var header: Parameters? { return nil }
}

extension Data: Body {
    public var requestData: Data { return self }
}

extension String: Body {
    public var requestData: Data {
        guard let data = data(using: .utf8) else {
            fatalError("cannot convert string to data: \(self)")
        }
        return data
    }
}
