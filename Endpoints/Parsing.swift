import Foundation

/// Describes an error that occured during parsing `Data`.
public enum ParsingError: LocalizedError {
    
    /// `Data` is missing.
    ///
    /// Thrown by `BaseClient.parse` when the response data is `nil`.
    case missingData
    
    /// `Data` is in an invalid format.
    ///
    /// Thrown by `DataParser` implementations.
    case invalidData(description: String)
 
    public var errorDescription: String? {
        switch self {
        case .missingData:
            return "no data"
        case .invalidData(let desc):
            return desc
        }
    }
}

/// A type that can convert a `Data` object into a specified `OutputType`.
///
/// Adopted by `Data`, `String`, `Dictionary` and `Array`.
///
/// Used by `Call` to define the expected response type for its associated
/// request.
public protocol DataParser {
    
    /// The type that can be produced by `self`.
    ///
    /// Defaults to `self`.
    associatedtype OutputType = Self
    
    /// Converts a `Data` object with a specified encoding to `OutputType`.
    ///
    /// - throws: `ParsingError` if `data` is not in the expected format.
    static func parse(data: Data, encoding: String.Encoding) throws -> OutputType
}

extension DataParser {
    
    /// Convenience helper for `DataParser` implementations that need to parse
    /// JSON data.
    public static func parseJSON(data: Data) throws -> Any {
        return try JSONSerialization.jsonObject(with: data, options: .allowFragments)
    }
}

extension Data: DataParser {
    public static func parse(data: Data, encoding: String.Encoding) throws -> Data {
        return data
    }
}

extension String: DataParser {
    public static func parse(data: Data, encoding: String.Encoding) throws -> String {
        if let string = String(data: data, encoding: encoding) {
            return string
        } else {
            throw ParsingError.invalidData(description: "String could not be parsed with encoding \(encoding.rawValue)")
        }
    }
}

extension Dictionary: DataParser {
    public static func parse(data: Data, encoding: String.Encoding) throws -> Dictionary {
        guard let dict = try parseJSON(data: data) as? Dictionary else {
            throw ParsingError.invalidData(description: "JSON structure is not an Object")
        }
        
        return dict
    }
}

extension Array: DataParser {
    public static func parse(data: Data, encoding: String.Encoding) throws -> Array {
        guard let array = try parseJSON(data: data) as? Array else {
            throw ParsingError.invalidData(description: "JSON structure is not an Array")
        }
        
        return array
    }
}