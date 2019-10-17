import Foundation

/// A `JSONDecodableParser` is a `DecodaableParser` that works with JSON representation.
/// It provides aa `jsonDecoder` to decode a response.
public protocol JSONDecodableParser: DecodableParser {
    var jsonDecoder: JSONDecoder { get }
}

public extension JSONDecodableParser {
    var jsonDecoder: JSONDecoder {
        return JSONDecoder()
    }

    func parse(data: Data) throws -> OutputType {
        return try jsonDecoder.decode(OutputType.self, from: data)
    }
}
