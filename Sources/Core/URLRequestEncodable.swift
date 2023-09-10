import Foundation

/// A type that can transform itself into an `URLRequest`.
///
/// This protocol is adopted by `Request`, `URLRequest`, `URL` and `Call`.
public protocol URLRequestEncodable: CustomDebugStringConvertible {

    /// Returns an `URLRequest` configured with the data encapsulated by `self`.
    var urlRequest: URLRequest { get }
}

extension URLRequestEncodable {

    /// Returns the value returned by `cURLRepresentation`.
    public var debugDescription: String {
        return cURLRepresentation
    }
}
