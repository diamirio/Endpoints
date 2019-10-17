import Foundation

/// A type that can convert a `Data` object into a specified `OutputType`.
///
/// Used by `Call` to define the expected response type for its associated
/// request.
public protocol DataParser {

    /// The type that can be produced by `self`.
    associatedtype OutputType

    /// Converts a `Data` object with a specified encoding to `OutputType`.
    ///
    /// - throws: `ParsingError` if `data` is not in the expected format.
    func parse(data: Data, encoding: String.Encoding) throws -> OutputType

    /// A `DataParser` needs to be initable without any arguments
    init()
}

public extension DataParser {

    /// Convenience helper for `DataParser` implementations that need to parse
    /// JSON data.
    func parseJSON(data: Data) throws -> Any {
        return try JSONSerialization.jsonObject(with: data, options: .allowFragments)
    }
}
