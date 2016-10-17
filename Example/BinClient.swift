//
//  BinAPI.swift
//  Endpoint
//
//  Created by Peter W on 13/10/2016.
//  Copyright © 2016 Tailored Apps. All rights reserved.
//

import Foundation
import Endpoints

class BinClient: BaseClient {
    init() {
        super.init(baseURL: URL(string: "https://httpbin.org")!)
    }
    
    override func validate(result: SessionTaskResult) throws {
        do {
            try statusCodeValidator.validate(result: result)
        } catch StatusCodeError.unacceptable(let code, let reason) {
            let message = result.httpResponse?.allHeaderFields["X-Error-Message"] as? String

            throw StatusCodeError.unacceptable(code: code, reason: message ?? reason)
        }
    }
}

protocol BinRequest: Request {}

extension BinRequest {
//    func start(completion: ((Result<ResponseType.OutputType>)->())?) {
//        BinAPI().start(endpoint: self) { result in
//        }
//    }
}

extension BinClient {
    struct GetOutput: Request {
        typealias ResponseType = OutputValue
        
        let value: String
        
        var path: String? { return "get" }
        var method: HTTPMethod { return .get }
        
        var query: Parameters? {
            return [ "value" : value ]
        }
    }
}

struct OutputValue: ResponseParser {
    let value: String
    
    static func parse(responseData: Data, encoding: String.Encoding) throws -> OutputValue {
        let dict = try Dictionary<String, Any>.parse(responseData: responseData, encoding: encoding)
        guard let args = dict["args"] as? [String: String], let value = args["value"] else {
            throw ParsingError.invalidData(description: "value not found")
        }
        return OutputValue(value: value)
    }
}
