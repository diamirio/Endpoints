// Copyright © 2023 DIAMIR. All Rights Reserved.

import Foundation

public extension Encodable {
    static var jsonEncoder: JSONEncoder {
        return JSONEncoder()
    }

    func toJSON() throws -> Data {
        return try Self.jsonEncoder.encode(self)
    }
}
