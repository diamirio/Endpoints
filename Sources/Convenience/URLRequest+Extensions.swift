//
//  URLRequest+URLRequestEncodable.swift
//  Endpoints
//
//  Created by Robin Mayerhofer on 27.08.19.
//  Copyright © 2019 Tailored Apps. All rights reserved.
//

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
