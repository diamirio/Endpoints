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
    
    override func validate(response: HTTPURLResponse) -> APIError? {
        var error = super.validate(response: response)
        
        
        if let error = error {
            switch error {
            case .unacceptableStatus(code: _, description: _):
                var message = response.allHeaderFields["X-Error-Message"] as? String
                message = message?.removingPercentEncoding
            default:
                
            }
            
        }
    }
}

protocol BinRequest: Request {}

extension BinRequest {
//    func start(completion: ((Result<ResponseType.OutputType>)->())?) {
//        BinAPI().call(endpoint: self) { result in
//        }
//    }
}

extension BinClient {
    struct GetOutput: Request {
        typealias RequestType = GetOutput
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
    
    static func parse(responseData: Data?, encoding: String.Encoding) throws -> OutputValue? {
        let dict = try Dictionary<String, Any>.parse(responseData: responseData, encoding: encoding)
        if let args = dict?["args"] as? [String: String], let value = args["value"] {
            return OutputValue(value: value)
        }
        return nil
    }
}
