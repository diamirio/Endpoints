import Foundation

/// A `ResponseParser` and can parse metadata from `response` using the static `decoder`
/// provided by itself if the output type is decodable and return the parsed output.
public protocol DecodableParser: Response, ResponseParser {}

public extension DecodableParser where OutputType: Decodable {

    static func parse(data: Data, encoding: String.Encoding) throws -> OutputType {
        return try decoder.decode(OutputType.self, from: data)
    }
}
