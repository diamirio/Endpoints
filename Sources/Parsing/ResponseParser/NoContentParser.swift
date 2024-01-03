// Copyright © 2023 DIAMIR. All Rights Reserved.

import Foundation

/// A `NoContentParser` is a convenience `ResponseParser`, when no response is expected
/// (e.g. 204 on success) or the response should be discarded.
public struct NoContentParser: ResponseParser {

    public typealias OutputType = Void

    public init() {}

    public func parse(response: HTTPURLResponse, data: Data) throws -> OutputType {
        return ()
    }

    public func parse(data: Data, encoding: String.Encoding) throws -> OutputType {
        return ()
    }
}
