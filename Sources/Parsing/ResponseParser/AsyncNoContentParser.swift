// Copyright © 2023 DIAMIR. All Rights Reserved.

import Foundation

/// A `AsyncNoContentParser` is a convenience `ResponseParser`, when no response is expected
/// (e.g. 204 on success) or the response should be discarded.
public struct AsyncNoContentParser: ResponseParser {
    public typealias OutputType = Any?

    public init() {}

    public func parse(response _: HTTPURLResponse, data _: Data) throws -> OutputType {
        .none
    }

    public func parse(data _: Data, encoding _: String.Encoding) throws -> OutputType {
        .none
    }
}
