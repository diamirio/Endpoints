import Foundation
import Endpoints

class BinClient: BaseClient {
    init() {
        super.init(baseURL: URL(string: "https://httpbin.org")!)
    }
    
    override func validate(result: URLSessionTaskResult) throws {
        do {
            try statusCodeValidator.validate(result: result)
        } catch StatusCodeError.unacceptable(let code, let reason) {
            let message = result.httpResponse?.allHeaderFields["X-Error-Message"] as? String

            throw StatusCodeError.unacceptable(code: code, reason: message ?? reason)
        }
    }
}

protocol BinCall: Call {}

extension BinClient {
    struct GetOutput: BinCall {
        typealias ResponseType = OutputValue
        
        let value: String
        
        var request: URLRequestEncodable {
            return Request(.get, "get", query: [ "value": value ])
        }
    }
    
    static func getOutput(value: String) -> DynamicCall<OutputValue> {
        return DynamicCall<OutputValue>(Request(.get, "get", query: [ "value": value]))
    }
}

struct OutputValue: ResponseParser {
    let value: String
    
    static func parse(data: Data, encoding: String.Encoding) throws -> OutputValue {
        let dict = try Dictionary<String, Any>.parse(data: data, encoding: encoding)
        guard let args = dict["args"] as? [String: String], let value = args["value"] else {
            throw ParsingError.invalidData(description: "value not found")
        }
        return OutputValue(value: value)
    }
}
