import Foundation

/// A `DecodableParser`` and can parse metadata into `OutputType`s.
/// The `OutputType` must always conform to `Decodable`
public protocol DecodableParser: ResponseParser where OutputType: Decodable {

    /// Converts a `Data` object to `OutputType`.
    ///
    /// - throws: if `data` is not in the expected format.
    func parse(data: Data) throws -> OutputType
}

/// implementation for `ResponseParser` parse method
public extension DecodableParser {
    func parse(data: Data, encoding: String.Encoding) throws -> OutputType {
        return try parse(data: data)
    }
}
