//
//  BinAPI.swift
//  Endpoint
//
//  Created by Peter W on 13/10/2016.
//  Copyright © 2016 Tailored Apps. All rights reserved.
//

import Foundation
import Endpoints

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

class BinAPI: API {
    init() {
        super.init(baseURL: URL(string: "https://httpbin.org")!)
    }
    
    override func validate(response: HTTPURLResponse) -> Error? {
        return nil
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

/////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////

struct InputValue: RequestData {
    let value: String
    
    var query: Parameters? {
        return [ "value": value ]
    }
}

struct CustomInputValue: RequestEncoder {
    let value: String
    
    func encode(request: URLRequest) -> URLRequest {
        return DynamicRequestData(query: ["value": value]).encode(request: request)
    }
}

extension BinAPI {
    static let GetOutputValue = DynamicEndpoint<InputValue, OutputValue>(.get, "get")
    static let DynamicRequest = DynamicEndpoint<DynamicRequestData, OutputValue>(.get, "get")
    static let CustomRequestEndpoint = DynamicEndpoint<CustomInputValue, OutputValue>(.get, "get")
    
    func getOutput(for value: String, completion: @escaping (Result<OutputValue>)->()) {
        let endpoint = DynamicEndpoint<DynamicRequestData, OutputValue>(.get, "get")
        let data = DynamicRequestData(query: ["value": value])
        
        self.call(endpoint: endpoint, with: data, completion: completion)
    }
    
    func outputRequest(with value: String) -> URLRequest {
        let endpoint = DynamicEndpoint<DynamicRequestData, OutputValue>(.get, "get")
        let data = DynamicRequestData(query: ["value": value])
        
        return self.request(for: endpoint, with: data)
    }
}
