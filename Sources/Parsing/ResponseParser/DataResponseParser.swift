//
//  DataResponseParser.swift
//  Endpoints
//
//  Created by Robin Mayerhofer on 21.10.19.
//  Copyright © 2019 Tailored Apps. All rights reserved.
//

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
