import Foundation

public struct AnyCall<Parser: ResponseParser>: Call {
    public typealias Parser = Parser

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
