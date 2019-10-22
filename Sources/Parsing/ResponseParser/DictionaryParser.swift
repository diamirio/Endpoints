//
//  DictionaryParser.swift
//  Endpoints
//
//  Created by Robin Mayerhofer on 21.10.19.
//  Copyright © 2019 Tailored Apps. All rights reserved.
//

import Foundation

/// A `DictionaryParser` is a convenience `ResponseParser` for dictionary output types.
public struct DictionaryParser<Key: Hashable, Value>: ResponseParser {

    public typealias OutputType = Dictionary<Key, Value>

    public init() {}

    public func parse(data: Data, encoding: String.Encoding) throws -> OutputType {
        guard let dict = try JSONSerialization.jsonObject(with: data, options: .allowFragments)  as? OutputType else {
            throw ParsingError.invalidData(description: "Could not parse JSON data to \(OutputType.self)")
        }
        return dict
    }
}
