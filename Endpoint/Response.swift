//
//  Response.swift
//  Endpoint
//
//  Created by Peter W on 13/10/2016.
//  Copyright © 2016 Tailored Apps. All rights reserved.
//

import Foundation

public protocol ParsableResponse {
    static func parse(responseData: Data?, encoding: String.Encoding) throws -> Self?
}

extension ParsableResponse {
    static func parseJSON(responseData: Data?) throws -> Any {
        return try JSONSerialization.jsonObject(with: responseData ?? Data(), options: .allowFragments)
    }
}

extension Data: ParsableResponse {
    public static func parse(responseData: Data?, encoding: String.Encoding) throws -> Data? {
        return responseData
    }
}

extension String: ParsableResponse {
    public static func parse(responseData: Data?, encoding: String.Encoding) throws -> String? {
        guard let data = responseData else {
            return nil
        }
        
        if let string = String(data: data, encoding: encoding) {
            return string
        } else {
            throw APIError.parsingError(description: "String could not be parsed with encoding: \(encoding)")
        }
    }
}

extension Dictionary: ParsableResponse {
    public static func parse(responseData: Data?, encoding: String.Encoding) throws -> Dictionary? {
        guard let dict = try parseJSON(responseData: responseData) as? Dictionary else {
            throw APIError.parsingError(description: "JSON structure is not an Object")
        }
        
        return dict
    }
}

extension Array: ParsableResponse {
    public static func parse(responseData: Data?, encoding: String.Encoding) throws -> Array? {
        guard let array = try parseJSON(responseData: responseData) as? Array else {
            throw APIError.parsingError(description: "JSON structure is not an Array")
        }
        
        return array
    }
}

public struct Result<Value: ParsableResponse> {
    public internal(set) var value: Value?
    public internal(set) var error: Error?
    
    public internal(set) var response: HTTPURLResponse?
    
    public var isSuccess: Bool {
        return !isError
    }
    
    public var isError: Bool {
        return error != nil
    }
    
    internal init(response: HTTPURLResponse?) {
        self.response = response
    }
}
