// Copyright © 2023 DIAMIR. All Rights Reserved.

import Foundation

/// A `JSONParser` is a `DecodableParser` that works with JSON representation.
/// It provides aa `jsonDecoder` to decode a response.
public struct JSONParser<T: Decodable>: ResponseParser {
    public typealias OutputType = T

    public let jsonDecoder: JSONDecoder

    public init() {
        self.jsonDecoder = JSONDecoder()
    }

    public func parse(data: Data, encoding _: String.Encoding) throws -> OutputType {
        try jsonDecoder.decode(OutputType.self, from: data)
    }
}
