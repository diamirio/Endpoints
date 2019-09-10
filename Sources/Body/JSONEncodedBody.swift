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

    /// Initialize with an encodable object
    ///
    /// - throws: The error thrown by `toJSON()`, if `jsonObject` cannot be encoded.
    public init(encodable: Encodable) throws {
        requestData = try encodable.toJSON()
    }

    /// Returns "Content-Type": "application/json".
    public var header: Parameters? {
        return [ "Content-Type" : "application/json" ]
    }
}
