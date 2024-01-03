// Copyright © 2023 DIAMIR. All Rights Reserved.

import Foundation

/// A `StringParser` os a convenience `ResponseParser`
/// for retrieving the response as a string
public struct StringParser: ResponseParser {

    public typealias OutputType = String

    public init() {}

    public func parse(data: Data, encoding: String.Encoding) throws -> String {
        guard let string = String(data: data, encoding: encoding) else {
            throw EndpointsParsingError.invalidData(description: "String could not be parsed with encoding \(encoding)")
        }
        return string
    }
}
