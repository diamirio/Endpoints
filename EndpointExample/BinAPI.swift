//
//  BinAPI.swift
//  Endpoint
//
//  Created by Peter W on 13/10/2016.
//  Copyright © 2016 Tailored Apps. All rights reserved.
//

import Foundation
import Endpoint

struct OutputValue: ResponseType {
    let value: String
    
    static func parse(responseData: Data?, encoding: String.Encoding) throws -> OutputValue? {
        let dict = try Dictionary<String, Any>.parse(responseData: responseData, encoding: encoding)
        if let args = dict?["args"] as? [String: String], let value = args["value"] {
            return OutputValue(value: value)
        }
        return nil
    }
}

struct InputValue: RequestEncoder {
    let value: String
    
    func encode(request: URLRequest) -> URLRequest {
        return RequestData(query: ["value": value]).encode(request: request)
    }
}

class BinAPI: HTTPAPI {
    static let GetOutputValue = Endpoint<InputValue, OutputValue>(.get, "get")
    
    init() {
        super.init(baseURL: URL(string: "https://httpbin.org")!)
    }
}
