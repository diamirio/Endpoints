import Foundation

/// Describes an error that occured during parsing `Data`.
public enum ParsingError: LocalizedError {
    
    /// `Data` is missing.
    ///
    /// Thrown by `AnyClient.parse` when the response data is `nil`.
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

public protocol ResponseDecoder {
    associatedtype DecodedType

    func decode(response: HTTPURLResponse, data: Data) throws -> DecodedType
}

extension ResponseDecoder {
    public func untyped() -> AnyResponseDecoder<DecodedType> {
        return AnyResponseDecoder(wrapped: self)
    }
}

public struct AnyResponseDecoder<T>: ResponseDecoder {
    private let _decode: (_ response: HTTPURLResponse, _ data: Data) throws -> T

    public init<D: ResponseDecoder>(wrapped: D) where D.DecodedType == T {
        self._decode = wrapped.decode
    }

    public func decode(response: HTTPURLResponse, data: Data) throws -> T {
        return try _decode(response, data)
    }
}

public protocol ResponseDecodable {
    static func responseDecoder() -> AnyResponseDecoder<Self>
}

extension String: ResponseDecodable {
    public static func responseDecoder() -> AnyResponseDecoder<String> {
        return StringDecoder().untyped()
    }
}

public class StringDecoder: ResponseDecoder {
    public func decode(response: HTTPURLResponse, data: Data) throws -> String {
        let encoding = response.stringEncoding
        if let string = String(data: data, encoding: encoding) {
            return string
        } else {
            throw ParsingError.invalidData(description: "String could not be parsed with encoding \(encoding.rawValue)")
        }
    }
}

extension Data: ResponseDecodable {
    public static func responseDecoder() -> AnyResponseDecoder<Data> {
        return DataResponseDecoder().untyped()
    }
}

class DataResponseDecoder: ResponseDecoder {
    func decode(response: HTTPURLResponse, data: Data) throws -> Data {
        return data
    }
}

extension Array: ResponseDecodable {
    public static func responseDecoder() -> AnyResponseDecoder<[Element]> {
        return JSONArrayDecoder<Element>().untyped()
    }
}

extension Dictionary: ResponseDecodable {
    public static func responseDecoder() -> AnyResponseDecoder<[Key: Value]> {
        return JSONDictionaryDecoder<Key, Value>().untyped()
    }
}

public extension JSONSerialization {
    static func jsonObject(with data: Data) throws -> Any {
        return try jsonObject(with: data, options: .allowFragments)
    }
}

public class JSONArrayDecoder<Element>: ResponseDecoder {
    public init() {}

    public func decode(response: HTTPURLResponse, data: Data) throws -> [Element] {
        guard let array = try JSONSerialization.jsonObject(with: data) as? [Element] else {
            throw ParsingError.invalidData(description: "JSON structure is not an Array")
        }

        return array
    }
}

public class JSONDictionaryDecoder<Key: Hashable, Value>: ResponseDecoder {
    public init() {}

    public func decode(response: HTTPURLResponse, data: Data) throws -> [Key: Value] {
        guard let dict = try JSONSerialization.jsonObject(with: data) as? [Key: Value] else {
            throw ParsingError.invalidData(description: "JSON structure is not an Object")
        }

        return dict
    }
}

public extension DataParser {
    
    /// Convenience helper for `DataParser` implementations that need to parse
    /// JSON data.
    public static func parseJSON(data: Data) throws -> Any {
        return try JSONSerialization.jsonObject(with: data, options: .allowFragments)
    }
}

/// A `DataParser` and can parse metadata from `response` and add
/// it to the parsed output.
public protocol ResponseParser: DataParser {
    static func parse(response: HTTPURLResponse, data: Data) throws -> OutputType
}

public extension ResponseParser {
    
    /// Uses `DataParser.parse(data:encoding)` to parse the response using
    /// 'response.stringEncoding'.
    public static func parse(response: HTTPURLResponse, data: Data) throws -> OutputType {
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

extension Array: ResponseParser {
    public static func parse(data: Data, encoding: String.Encoding) throws -> Array {
        guard let array = try parseJSON(data: data) as? Array else {
            throw ParsingError.invalidData(description: "JSON structure is not an Array")
        }
        
        return array
    }
}

public extension HTTPURLResponse {
    
    /// Returns the `textEncodingName`s corresponding `String.Encoding`
    /// or `utf8`, if this is not possible.
    var stringEncoding: String.Encoding {
        var encoding = String.Encoding.utf8
        
        if let textEncodingName = textEncodingName {
            let cfStringEncoding = CFStringConvertIANACharSetNameToEncoding(textEncodingName as CFString)
            encoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(cfStringEncoding))
        }
        
        return encoding
    }
}
