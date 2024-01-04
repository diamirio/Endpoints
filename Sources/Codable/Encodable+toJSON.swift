// Copyright © 2023 DIAMIR. All Rights Reserved.

import Foundation

public extension Encodable {
    static var jsonEncoder: JSONEncoder {
        JSONEncoder()
    }

    func toJSON() throws -> Data {
        try Self.jsonEncoder.encode(self)
    }
}
