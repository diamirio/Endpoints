// Copyright © 2023 DIAMIR. All Rights Reserved.

import Foundation

/// A `JSONParser` is a `DecodableParser` that works with JSON representation.
/// It provides aa `jsonDecoder` to decode a response.
open class JSONParser<T: Decodable>: ResponseParser {
    public typealias OutputType = T

    public required init() {}

    open var jsonDecoder: JSONDecoder {
        JSONDecoder()
    }

    public func parse(data: Data, encoding _: String.Encoding) throws -> OutputType {
        try jsonDecoder.decode(OutputType.self, from: data)
    }
}
