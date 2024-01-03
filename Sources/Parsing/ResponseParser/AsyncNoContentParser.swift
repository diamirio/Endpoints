// Copyright © 2023 DIAMIR. All Rights Reserved.

import Foundation

/// A `AsyncNoContentParser` is a convenience `ResponseParser`, when no response is expected
/// (e.g. 204 on success) or the response should be discarded.
public struct AsyncNoContentParser: ResponseParser {

    public typealias OutputType = Optional<Any>

    public init() {}

    public func parse(response: HTTPURLResponse, data: Data) throws -> OutputType {
        return .none
    }

    public func parse(data: Data, encoding: String.Encoding) throws -> OutputType {
        return .none
    }
}
