import Foundation

/// A `DataParser` and can parse metadata from `response` and add
/// it to the parsed output.
public protocol ResponseParser: DataParser {
    static func parse(response: HTTPURLResponse, data: Data) throws -> OutputType
}

public extension ResponseParser {

    /// Uses `DataParser.parse(data:encoding)` to parse the response using
    /// 'response.stringEncoding'.
    static func parse(response: HTTPURLResponse, data: Data) throws -> OutputType {
        return try self.parse(data: data, encoding: response.stringEncoding)
    }
}

extension Data: ResponseParser {
    public static func parse(data: Data, encoding: String.Encoding) throws -> Data {
        return data
    }
}

extension String: ResponseParser {
    public static func parse(data: Data, encoding: String.Encoding) throws -> String {
        if let string = String(data: data, encoding: encoding) {
            return string
        } else {
            throw ParsingError.invalidData(description: "String could not be parsed with encoding \(encoding.rawValue)")
        }
    }
}

extension Dictionary: ResponseParser {
    public static func parse(data: Data, encoding: String.Encoding) throws -> Dictionary {
        guard let dict = try parseJSON(data: data) as? Dictionary else {
            throw ParsingError.invalidData(description: "JSON structure is not an Object")
        }

        return dict
    }
}
