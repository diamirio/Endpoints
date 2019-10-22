import Foundation

/// A `DataParser` and can parse metadata from `response` and add
/// it to the parsed output.
public protocol ResponseParser: DataParser {
    func parse(response: HTTPURLResponse, data: Data) throws -> OutputType
}

public extension ResponseParser {
    /// Uses `DataParser.parse(data:encoding)` to parse the response using
    /// 'response.stringEncoding'.
    func parse(response: HTTPURLResponse, data: Data) throws -> OutputType {
        return try self.parse(data: data, encoding: response.stringEncoding)
    }
}
