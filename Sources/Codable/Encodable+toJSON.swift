import Foundation

public extension Encodable {
    static var encoder: JSONEncoder {
        return JSONEncoder()
    }

    func toJSON() throws -> Data {
        return try Self.encoder.encode(self)
    }
}
