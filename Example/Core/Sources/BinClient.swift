import Foundation
import Endpoints

// MARK: -
// MARK: Client

public class BinClient: AnyClient {
    init() {
        super.init(baseURL: URL(string: "https://httpbin.org")!)
    }
    
    override public func validate(result: URLSessionTaskResult) throws {
        do {
            try result.httpResponse?.validateStatusCode()
        } catch let error as StatusCodeError {
            let message = result.httpResponse?.allHeaderFields["X-Error-Message"] as? String

            throw error.with(reason: message)
        }
    }
}

// MARK: 
// MARK: Requests

protocol BinCall: Call {}

public extension BinClient {
    public struct GetOutput: BinCall {
        public typealias DecodedType = OutputValue
        
        public var value: String
        
        public var request: URLRequestEncodable {
            return Request(.get, "get", query: [ "value": value ])
        }
    }
    
    static func getOutput(value: String) -> AnyCall<OutputValue> {
        return AnyCall<OutputValue>(Request(.get, "get", query: [ "value": value]))
    }
}

// MARK: -
// MARK: Responses

public struct OutputValue: ResponseDecodable {
    public var value: String
    
    public static var responseDecoder: ResponseDecoder<OutputValue> {
        return { response, data in
            let dict = try [String: Any].responseDecoder(response, data)
            guard let args = dict["args"] as? [String: String], let value = args["value"] else {
                throw DecodingError.invalidData(description: "value not found")
            }
            return OutputValue(value: value)
        }
    }
}
