//
//  JSONEncodedBody.swift
//  Endpoints
//
//  Created by Robin Mayerhofer on 27.08.19.
//  Copyright © 2019 Tailored Apps. All rights reserved.
//

import Foundation

/// A type representing a JSON encoded HTTP request body.
public struct JSONEncodedBody: Body {
    public let requestData: Data

    /// Initialize with a JSON object, an `Array` or a `Dictionary`.
    ///
    /// - throws: The error thrown by `JSONSerialization.data(withJSONObject:options:)`, if `jsonObject`
    /// cannot be encoded.
    public init(jsonObject: Any) throws {
        requestData = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
    }

    /// Returns "Content-Type": "application/json".
    public var header: Parameters? {
        return [ "Content-Type" : "application/json" ]
    }
}

