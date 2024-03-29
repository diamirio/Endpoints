// Copyright © 2023 DIAMIR. All Rights Reserved.

import Foundation

/// A type that can transform itself into an `URLRequest`.
///
/// This protocol is adopted by `Request`, `URLRequest`, `URL` and `Call`.
public protocol URLRequestEncodable: CustomDebugStringConvertible {
    /// Returns an `URLRequest` configured with the data encapsulated by `self`.
    var urlRequest: URLRequest { get }
}

public extension URLRequestEncodable {
    /// Returns the value returned by `cURLRepresentation`.
    var debugDescription: String {
        cURLRepresentation
    }
}
