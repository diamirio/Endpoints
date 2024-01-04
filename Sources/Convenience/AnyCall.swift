// Copyright © 2023 DIAMIR. All Rights Reserved.

import Foundation

public struct AnyCall<Parser: ResponseParser>: Call {
    public typealias Parser = Parser

    public typealias ValidationBlock = (HTTPURLResponse?, Data?) throws -> Void

    public var request: URLRequestEncodable

    public var validate: ValidationBlock?

    public init(
        _ request: URLRequestEncodable,
        validate: ValidationBlock? = nil
    ) {
        self.request = request
        self.validate = validate
    }

    public func validate(
        response: HTTPURLResponse?,
        data: Data?
    ) throws {
        try validate?(response, data)
    }
}
