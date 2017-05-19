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

/// Because the swift default decoders (`JSONDecoder` and `PropertyListDecoder`
/// use a private nested type for this) do not themselves conform to the 
/// `Decoder` protocol, we must provide our own protocol to be able to 
/// generically use these implementations without being tied to a particular decoding.
public protocol DecodingDecoder {
    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T
}

extension JSONDecoder: DecodingDecoder {}
extension PropertyListDecoder: DecodingDecoder {}

/// A response parser that uses a `Decoder` (or rather our own, unfortunately 
/// necessary, abstraction thereof: `DecodingDecoder`) to turn (response) data
/// into an object.
public protocol DecodableResponseParser: ResponseParser, Decodable {
    static var decoder: DecodingDecoder { get }
}

extension DecodableResponseParser {
    public static func parse(data: Data, encoding: String.Encoding) throws -> Self {
        return try decoder.decode(self, from: data)
    }
}

/// A convenience 'DecodableResponseParser' that uses an
/// instance of `JSONDecoder` (provided by a protocol extension).
///
/// Override the static `DecodableResponseParser.decoder` to use a
/// specifically configure instance of `JSONDecoder`.
protocol JSONDecodable: DecodableResponseParser {}

extension JSONDecodable {
    static var decoder: DecodingDecoder {
        return JSONDecoder()
    }
}

extension JSONDecodable {
    public static func parse(data: Data, encoding: String.Encoding) throws -> Self {
        return try JSONDecoder().decode(self, from: data)
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
