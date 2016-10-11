//
//  DataParsable.swift
//  Pods
//
//  Created by Thomas Koller on 04/10/16.
//
//

import Foundation

public protocol DataParsable {
    //FIXME: declare return value as "instancetyp", when swift lets me
    static func parse(data: Data?, encoding: String.Encoding) throws -> Any
}

extension DataParsable {
    public static func parseString(data: Data?, encoding: String.Encoding) throws -> Any {
        guard let data = data else {
            return ""
        }
        
        let encoding: String.Encoding = String.Encoding.isoLatin1
        
        if let string = String(data: data, encoding: encoding) {
            return string
        } else {
            throw PWHTTPError.parsingError(description: "String could not be serialized with encoding: \(encoding)")
        }
    }
    
    public static func parseJSON(data: Data?) throws -> Any {
        return try JSONSerialization.jsonObject(with: data ?? Data(), options: .allowFragments)
    }
    
    public static func parseJSONObject(data: Data?) throws -> [String: Any] {
        if let dict = try parseJSON(data: data) as? [String: Any] {
            return dict
        } else {
            throw PWHTTPError.parsingError(description: "JSON structure is not an Object")
        }
    }
    
    public static func parseJSONArray(data: Data?) throws -> [[String: Any]] {
        if let array = try parseJSON(data: data) as? [[String: Any]] {
            return array
        } else {
            throw PWHTTPError.parsingError(description: "JSON structure is not an Array")
        }
    }
}

extension Data: DataParsable {
    public static func parse(data: Data?, encoding: String.Encoding) throws -> Any {
        return data ?? Data()
    }
}

extension String: DataParsable {
    public typealias Out = String
    
    public static func parse(data: Data?, encoding: String.Encoding) throws -> Any {
        return try parseString(data: data, encoding: encoding)
    }
}

extension Dictionary: DataParsable {
    public static func parse(data: Data?, encoding: String.Encoding) throws -> Any {
        return try parseJSONObject(data: data)
    }
}

extension Array: DataParsable {
    public static func parse(data: Data?, encoding: String.Encoding) throws -> Any {
        return try parseJSONArray(data: data)
    }
}
