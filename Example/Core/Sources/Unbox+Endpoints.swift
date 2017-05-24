import Foundation
import Unbox
import Endpoints

public extension Unboxable where Self: ResponseDecodable {
    static func responseDecoder() -> Decoder {
        return decodeUnboxable
    }

    static func decodeUnboxable(response: HTTPURLResponse, data: Data) throws -> Self {
        return try unbox(data: data)
    }
}

public extension Array where Element: Unboxable {
    static func responseDecoder() -> Decoder {
        return decodeUnboxableArray
    }

    static func decodeUnboxableArray(response: HTTPURLResponse, data: Data) throws -> [Element] {
        return try Unbox.unbox(data: data)
    }
}
