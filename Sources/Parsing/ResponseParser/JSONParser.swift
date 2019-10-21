//
//  JSONParser.swift
//  
//
//  Created by Robin Mayerhofer on 17.10.19.
//

import Foundation

/// A `JSONParser` is a `DecodableParser` that works with JSON representation.
/// It provides aa `jsonDecoder` to decode a response.
open class JSONParser<T: Decodable>: ResponseParser {

    public typealias OutputType = T

    required public init() {}

    open var jsonDecoder: JSONDecoder {
        return JSONDecoder()
    }

    public func parse(data: Data, encoding: String.Encoding) throws -> OutputType {
        return try jsonDecoder.decode(OutputType.self, from: data)
    }
}
