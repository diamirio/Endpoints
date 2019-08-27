//
//  AnyCall.swift
//  Endpoints
//
//  Created by Robin Mayerhofer on 27.08.19.
//  Copyright © 2019 Tailored Apps. All rights reserved.
//

import Foundation

public struct AnyCall<Response: ResponseParser>: Call {
    public typealias ResponseType = Response

    public typealias ValidationBlock = (URLSessionTaskResult) throws -> ()

    public var request: URLRequestEncodable

    public var validate: ValidationBlock?

    public init(_ request: URLRequestEncodable, validate: ValidationBlock? = nil) {
        self.request = request

        self.validate = validate
    }

    public func validate(result: URLSessionTaskResult) throws {
        try validate?(result)
    }
}
