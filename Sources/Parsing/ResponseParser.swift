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

/// A `EmptyResponse` is a convenience `ResponseParser`, when no response is expected
/// (e.g. 204 on success) or the response should be discarded.
public struct EmptyResponseParser: ResponseParser {

    public typealias OutputType = Void

    public init() {}

    public func parse(response: HTTPURLResponse, data: Data) throws -> OutputType {
        return ()
    }

    public func parse(data: Data, encoding: String.Encoding) throws -> OutputType {
        return ()
    }
}

/// A `DataResponseParser` is a convenience `ResponseParser`, when no response is expected
/// (e.g. 204 on success) or the response should be discarded.
public struct DataResponseParser: ResponseParser {

    public typealias OutputType = Data

    public init() {}

    public func parse(data: Data, encoding: String.Encoding) throws -> OutputType {
        return data
    }
}

/// A `DictionaryParser` is a convenience `ResponseParser` for dictionary output types.
public struct DictionaryParser<Key: Hashable, Value>: ResponseParser {

    public typealias OutputType = Dictionary<Key, Value>

    public init() {}

    public func parse(data: Data, encoding: String.Encoding) throws -> OutputType {
        guard let dict = try parseJSON(data: data) as? OutputType else {
            throw ParsingError.invalidData(description: "Could not parse JSON data to \(OutputType.self)")
        }
        return dict
    }

}

public struct StringParser: ResponseParser {

    public typealias OutputType = String

    public init() {}

    public func parse(data: Data, encoding: String.Encoding) throws -> String {
        guard let string = String(data: data, encoding: encoding) else {
            throw ParsingError.invalidData(description: "String could not be parsed with encoding \(encoding)")
        }
        return string
    }
}
