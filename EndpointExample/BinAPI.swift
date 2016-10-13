//
//  BinAPI.swift
//  Endpoint
//
//  Created by Peter W on 13/10/2016.
//  Copyright © 2016 Tailored Apps. All rights reserved.
//

import Foundation
import Endpoint

struct OutputValue: ParsableResponse {
    let value: String
    
    static func parse(responseData: Data?, encoding: String.Encoding) throws -> OutputValue? {
        let dict = try Dictionary<String, Any>.parse(responseData: responseData, encoding: encoding)
        if let args = dict?["args"] as? [String: String], let value = args["value"] {
            return OutputValue(value: value)
        }
        return nil
    }
}

struct CustomInputValue: RequestEncoder {
    let value: String
    
    func encode(request: URLRequest) -> URLRequest {
        return DynamicRequestData(query: ["value": value]).encode(request: request)
    }
}

struct InputValue: RequestData {
    let value: String
    
    var query: Parameters? {
        return [ "value": value ]
    }
}

class BinAPI: HTTPAPI {
    static let GetOutputValue = Endpoint<InputValue, OutputValue>(.get, "get")
    static let DynamicEndpoint = Endpoint<DynamicRequestData, OutputValue>(.get, "get")
    static let CustomRequestEndpoint = Endpoint<CustomInputValue, OutputValue>(.get, "get")
    
    init() {
        super.init(baseURL: URL(string: "https://httpbin.org")!)
    }
    
    func getOutput(for value: String, completion: @escaping (Result<OutputValue>)->()) {
        let endpoint = Endpoint<DynamicRequestData, OutputValue>(.get, "get")
        let data = DynamicRequestData(query: ["value": value])
        
        self.call(endpoint: endpoint, with: data, completion: completion)
    }
    
    func outputRequest(with value: String) -> URLRequest {
        let endpoint = Endpoint<DynamicRequestData, OutputValue>(.get, "get")
        let data = DynamicRequestData(query: ["value": value])
        
        return self.request(for: endpoint, with: data)
    }
}
