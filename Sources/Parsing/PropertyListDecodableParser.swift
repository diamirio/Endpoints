import Foundation

/// A `JSONDecodableParser` is a `DecodaableParser` that works with property listss.
/// It provides aa `propertyListDecoder` to decode a response.
public protocol PropertyListDecodableParser: DecodableParser {
    static var propertyListDecoder: PropertyListDecoder { get }
}

public extension PropertyListDecodableParser {
    static var propertyListDecoder: PropertyListDecoder {
        return PropertyListDecoder()
    }

    static func parse(data: Data) throws -> OutputType {
        return try propertyListDecoder.decode(OutputType.self, from: data)
    }
}

/// A `PropertySelfDecodable` is a decodable type, that provides a `propertyListDecoder`
/// to decode itself and can handle the parsing itself.
public typealias PropertyListSelfDecodable = Decodable & PropertyListDecodableParser
