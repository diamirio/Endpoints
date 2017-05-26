import Foundation

/// Used by `Call` to define the expected response type for its associated
/// request.
public protocol ResponseDecoder {
    associatedtype DecodedType = Self
    typealias Decoder = (HTTPURLResponse, Data) throws -> DecodedType

    /// Returns a `Decoder` block, responsible for creating
    /// instances of this type from a `HTTPURLResponse` and corresponding
    /// body `Data`.
    static func responseDecoder() -> Decoder
}

public extension URLSessionTaskResult {
    /// Throws `error` if not-nil.
    ///
    /// Throws 'DecodingError.missingData` if `data`
    /// or `httpResponse` is `nil`.
    ///
    /// Finally delegates decoding to the block returned by
    /// `decoder.responseDecoder()` and returns the decoded
    ///  object or rethrows a decoding error.
    func decode<D>(with decoder: (HTTPURLResponse, Data) throws -> D) throws -> D {
        if let error = error {
            throw error
        }

        guard let data = data, let response = httpResponse else {
            throw DecodingError.missingData
        }

        return try decoder(response, data)
    }
}


// MARK: - Decodable Support

extension String: ResponseDecoder {
    public static func responseDecoder() -> Decoder {
        return decodeString
    }

    public static func decodeString(response: HTTPURLResponse, data: Data) throws -> String {
        let encoding = response.stringEncoding
        if let string = String(data: data, encoding: encoding) {
            return string
        } else {
            throw DecodingError.invalidData(description: "String could not be decoded with encoding \(encoding.rawValue)")
        }
    }
}

extension Data: ResponseDecoder {
    public static func responseDecoder() -> Decoder {
        return decodeData
    }

    public static func decodeData(response: HTTPURLResponse, data: Data) throws -> Data {
        return data
    }
}

extension Array: ResponseDecoder {
    public static func responseDecoder() -> Decoder {
        return decodeJSONArray
    }

    public static func decodeJSONArray(response: HTTPURLResponse, data: Data) throws -> [Element] {
        guard let array = try JSONSerialization.jsonObject(with: data) as? [Element] else {
            throw DecodingError.invalidData(description: "JSON structure is not an Array")
        }

        return array
    }
}

extension Dictionary: ResponseDecoder {
    public static func responseDecoder() -> Decoder {
        return decodeJSONDictionary
    }

    public static func decodeJSONDictionary(response: HTTPURLResponse, data: Data) throws -> [Key: Value] {
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
