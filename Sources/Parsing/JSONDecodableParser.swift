import Foundation

/// A `JSONDecodableParser` is a `DecodaableParser` that works with JSON representation.
/// It provides aa `jsonDecoder` to decode a response.
public protocol JSONDecodableParser: DecodableParser {
    static var jsonDecoder: JSONDecoder { get }
}

public extension JSONDecodableParser {
    static var jsonDecoder: JSONDecoder {
        return JSONDecoder()
    }

    static func parse(data: Data) throws -> OutputType {
        return try jsonDecoder.decode(OutputType.self, from: data)
    }
}

/// A `JSONSelfDecodable` is a decodable type, that provides a `jsonDecoder`
/// to decode itself and can handle the parsing itself.
public typealias JSONSelfDecodable = Decodable & JSONDecodableParser
