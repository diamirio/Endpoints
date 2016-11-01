import Foundation

public protocol Call: URLRequestEncodable, ResponseValidator {
    associatedtype ResponseType: DataParser
    
    var request: URLRequestEncodable { get }
}

public extension Call {
    public func encode(withBaseURL baseURL: URL) -> URLRequest {
        return request.encode(withBaseURL: baseURL)
    }
    
    func validate(result: URLSessionTaskResult) throws {
        //no validation by default
    }
}

public struct DynamicCall<Response: DataParser>: Call {
    public typealias ResponseType = Response
    
    public typealias EncodingBlock = (URLRequest)->(URLRequest)
    public typealias ValidationBlock = (URLSessionTaskResult) throws ->()
    
    public var request: URLRequestEncodable
    
    public var encode: EncodingBlock?
    public var validate: ValidationBlock?
    
    public init(_ request: Request, encode: EncodingBlock?=nil, validate: ValidationBlock?=nil) {
        self.request = request
        
        self.validate = validate
        self.encode = encode
    }
    
    public func encode(withBaseURL baseURL: URL) -> URLRequest {
        let urlRequest = request.encode(withBaseURL: baseURL)
        return encode?(urlRequest) ?? urlRequest
    }
    
    public func validate(result: URLSessionTaskResult) throws {
        try validate?(result)
    }
}

public enum StatusCodeError: Error {
    case unacceptable(code: Int, reason: String?)
}

extension StatusCodeError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unacceptable(let code, let reason):
            return reason ?? HTTPURLResponse.localizedString(forStatusCode: code)
        }
    }
}

public protocol ResponseValidator {
    func validate(result: URLSessionTaskResult) throws
}

public class StatusCodeValidator: ResponseValidator {
    public func isAcceptableStatus(code: Int) -> Bool {
        return (200..<300).contains(code)
    }
    
    public func validate(result: URLSessionTaskResult) throws {
        if let code = result.httpResponse?.statusCode, !isAcceptableStatus(code: code) {
            throw StatusCodeError.unacceptable(code: code, reason: nil)
        }
    }
}

public protocol Client {
    func encode<C: Call>(call: C) -> URLRequest
    func parse<C: Call>(sessionTaskResult result: URLSessionTaskResult, for call: C) throws -> C.ResponseType.OutputType
}

public struct URLSessionTaskResult {
    public var response: URLResponse?
    public var data: Data?
    public var error: Error?
    
    public var httpResponse: HTTPURLResponse? {
        return response as? HTTPURLResponse
    }
}

open class BaseClient: Client, ResponseValidator {
    public let baseURL: URL
    public private(set) lazy var statusCodeValidator = StatusCodeValidator()
    
    public init(baseURL: URL) {
        self.baseURL = baseURL
    }
    
    open func encode<C: Call>(call: C) -> URLRequest {
        return call.encode(withBaseURL: baseURL)
    }
    
    public func parse<C: Call>(sessionTaskResult result: URLSessionTaskResult, for call: C) throws -> C.ResponseType.OutputType {
        if let error = result.error {
            throw error
        }
        
        try validate(result: result, for: call)
        
        if let data = result.data {
            return try C.ResponseType.self.parse(data: data, encoding: .utf8) //TODO: use response encoding, if present
        } else {
            throw ParsingError.missingData
        }
    }
    
    public func validate<C: Call>(result: URLSessionTaskResult, for call: C) throws {
        try validate(result: result) //global validation
        try call.validate(result: result) //request-specific validation
    }
    
    open func validate(result: URLSessionTaskResult) throws {
        try statusCodeValidator.validate(result: result)
    }
}
