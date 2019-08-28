import Foundation

extension URLRequest: URLRequestEncodable {
    public var urlRequest: URLRequest {
        return self
    }
}

public extension URLRequest {

    /// Adds or replaces all header fields with the given values.
    ///
    /// - note: If a value was previously set for the given header
    /// field, that value is replaced.
    mutating func apply(header: Parameters?) {
        header?.forEach { setValue($1, forHTTPHeaderField: $0) }
    }
}
