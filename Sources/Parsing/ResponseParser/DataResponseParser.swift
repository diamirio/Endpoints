// Copyright © 2023 DIAMIR. All Rights Reserved.

import Foundation

/// A `DataResponseParser` is a convenience `ResponseParser`
/// for directly receiving the data of the response.
public struct DataResponseParser: ResponseParser {

    public typealias OutputType = Data

    public init() {}

    public func parse(data: Data, encoding: String.Encoding) throws -> OutputType {
        return data
    }
}
