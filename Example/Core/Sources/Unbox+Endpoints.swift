import Foundation
import Unbox
import Endpoints

public protocol UnboxableResponseDecodable: Unboxable, ResponseDecodable {}

public extension UnboxableResponseDecodable {
    static func responseDecoder() -> AnyResponseDecoder<Self> {
        return UnboxableDecoder<Self>().untyped()
    }
}

public class UnboxableDecoder<U: Unboxable>: ResponseDecoder {
    public func decode(response: HTTPURLResponse, data: Data) throws -> U {
        return try unbox(data: data)
    }
}

public protocol UnboxableParser: Unboxable, ResponseParser {}

public extension UnboxableParser {
    static func parse(data: Data, encoding: String.Encoding) throws -> Self {
        return try unbox(data: data)
    }
}

public class UnboxableArray<Element: Unboxable>: ResponseParser {
    public typealias OutputType = [Element]
    
    public static func parse(data: Data, encoding: String.Encoding) throws -> OutputType {
        return try unbox(data: data)
    }
}
