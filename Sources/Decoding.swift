import Foundation

/// Used by `Call` to define the expected response type for its associated
/// request.
public protocol ResponseDecodable {
    typealias ResponseDecoder = (_ response: HTTPURLResponse, _ data: Data)->(Self)

    /// Returns a type-erased `ResponseDecoder`, responsible for creating
    /// instances of this type from a `HTTPURLResponse` and corresponding
    /// body `Data`.
    static func responseDecoder() -> AnyResponseDecoder<Self>
}

/// A type that can convert a `Data` object into a specified `DecodedType`.
/// Can also decode metadata from `HTTPURLResponse` and include it in the 
/// decoded type instance.
///
/// Adopted by `Data`, `String`, `Dictionary<String, Any>` and `Array<Any>`
/// (the last two use JSONSerialization to decode JSON objects).
public protocol ResponseDecoder {
    /// The type that can be decoded by `self`.
    associatedtype DecodedType

    /// Decodes a `HTTPURLRespnonse` and it's `Data` into `DecodedType`.
    ///
    /// - throws: `DecodingError` if `data` is not in the expected format.
    func decode(response: HTTPURLResponse, data: Data) throws -> DecodedType
}

// MARK: - Decodable Support

extension String: ResponseDecodable {
    public static func responseDecoder() -> AnyResponseDecoder<String> {
        return AnyResponseDecoder(StringDecoder())
    }
}

extension Data: ResponseDecodable {
    public static func responseDecoder() -> AnyResponseDecoder<Data> {
        return AnyResponseDecoder(DataResponseDecoder())
    }
}

extension Array: ResponseDecodable {
    public static func responseDecoder() -> AnyResponseDecoder<[Element]> {
        return AnyResponseDecoder(JSONArrayDecoder<Element>())
    }
}

extension Dictionary: ResponseDecodable {
    public static func responseDecoder() -> AnyResponseDecoder<[Key: Value]> {
        return AnyResponseDecoder(JSONDictionaryDecoder<Key, Value>())
    }
}

// MARK: - Decoders

public class DataResponseDecoder: ResponseDecoder {
    public func decode(response: HTTPURLResponse, data: Data) throws -> Data {
        return data
    }
}

public class StringDecoder: ResponseDecoder {
    public init() {}

    public func decode(response: HTTPURLResponse, data: Data) throws -> String {
        let encoding = response.stringEncoding
        if let string = String(data: data, encoding: encoding) {
            return string
        } else {
            throw DecodingError.invalidData(description: "String could not be decoded with encoding \(encoding.rawValue)")
        }
    }
}

public class JSONArrayDecoder<Element>: ResponseDecoder {
    public init() {}

    public func decode(response: HTTPURLResponse, data: Data) throws -> [Element] {
        guard let array = try JSONSerialization.jsonObject(with: data) as? [Element] else {
            throw DecodingError.invalidData(description: "JSON structure is not an Array")
        }

        return array
    }
}

public class JSONDictionaryDecoder<Key: Hashable, Value>: ResponseDecoder {
    public init() {}

    public func decode(response: HTTPURLResponse, data: Data) throws -> [Key: Value] {
        guard let dict = try JSONSerialization.jsonObject(with: data) as? [Key: Value] else {
            throw DecodingError.invalidData(description: "JSON structure is not an Object")
        }

        return dict
    }
}

// MARK: - Error

/// Describes an error that occured during decoding `Data`.
public enum DecodingError: LocalizedError {

    /// `Data` is missing.
    ///
    /// Thrown by `AnyClient.decode` when the response data is `nil`.
    case missingData

    /// `Data` is in an invalid format.
    ///
    /// Thrown by `ResponseDecoder` implementations.
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

// MARK: - Type Erasure

public struct AnyResponseDecoder<T>: ResponseDecoder {
    private let _decode: (_ response: HTTPURLResponse, _ data: Data) throws -> T

    public init<D: ResponseDecoder>(_ base: D) where D.DecodedType == T {
        self._decode = base.decode
    }

    public func decode(response: HTTPURLResponse, data: Data) throws -> T {
        return try _decode(response, data)
    }
}

// MARK: - Convenience Helper

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

public extension JSONSerialization {
    static func jsonObject(with data: Data) throws -> Any {
        return try jsonObject(with: data, options: .allowFragments)
    }
}
