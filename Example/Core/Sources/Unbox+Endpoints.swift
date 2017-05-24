import Foundation
import Unbox
import Endpoints

public protocol UnboxableResponseDecodable: Unboxable, ResponseDecodable {}

public extension UnboxableResponseDecodable {
    static func responseDecoder() -> AnyResponseDecoder<Self> {
        return AnyResponseDecoder(UnboxableDecoder<Self>())
    }
}

extension Array where Element: Unboxable {
    static func responseDecoder() -> AnyResponseDecoder<[Element]> {
        return AnyResponseDecoder(UnboxableArrayDecoder<Element>())
    }
}

public class UnboxableDecoder<U: Unboxable>: ResponseDecoder {
    public func decode(response: HTTPURLResponse, data: Data) throws -> U {
        return try unbox(data: data)
    }
}

public class UnboxableArrayDecoder<U: Unboxable>: ResponseDecoder {
    public func decode(response: HTTPURLResponse, data: Data) throws -> [U] {
        return try unbox(data: data)
    }
}
