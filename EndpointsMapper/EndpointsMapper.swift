//
//  EndpointsMapper.swift
//  Endpoints
//
//  Created by Peter W on 14/10/2016.
//  Copyright © 2016 Tailored Apps. All rights reserved.
//

import Foundation
import ObjectMapper
import Endpoints

public extension Mappable {
    func toData() throws -> Data {
        return try JSONSerialization.data(withJSONObject: toJSON(), options: .prettyPrinted)
    }
}

extension DynamicRequestData {
    public init(mappable: Mappable?=nil) throws {
        try self.init(body: mappable?.toData())
    }
}

public protocol MappableEndpointRequest: EndpointRequest {
    associatedtype MappableType: Mappable
    
    var mappable: MappableType { get }
}

public extension MappableEndpointRequest {
    var method: HTTPMethod { return .post }
    
    var body: Data? {
        return try! mappable.toData()
    }
}

public protocol MappableResponse: Mappable, ResponseParser {}

public extension MappableResponse {
    public static func parse(responseData: Data?, encoding: String.Encoding) throws -> Self? {
        guard let dict = try parseJSON(responseData: responseData) as? [String: Any] else {
            throw APIError.parsingError(description: "JSON structure is not a Dictionary")
        }
        
        guard let object:Self = Mapper().map(JSON: dict) else {
            throw APIError.parsingError(description: "JSON structure could not be mapped to \(self) class")
        }
        
        return object
    }
}
