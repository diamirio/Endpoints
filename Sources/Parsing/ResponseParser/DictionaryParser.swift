// Copyright © 2023 DIAMIR. All Rights Reserved.

import Foundation

/// A `DictionaryParser` is a convenience `ResponseParser` for dictionary output types.
public struct DictionaryParser<Key: Hashable, Value>: ResponseParser {
    public typealias OutputType = [Key: Value]

    public init() {}

    public func parse(data: Data, encoding _: String.Encoding) throws -> OutputType {
        guard let dict = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? OutputType else {
            throw EndpointsParsingError.invalidData(description: "Could not parse JSON data to \(OutputType.self)")
        }
        return dict
    }
}
