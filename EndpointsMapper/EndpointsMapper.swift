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

extension JSONEncodedBody {
    init<M: BaseMappable>(mappable: M) throws {
        let json = Mapper<M>().toJSON(mappable)
        try self.init(jsonObject: json)
    }
}

public protocol MappableResponse: Mappable, ResponseParser {}

public extension MappableResponse {
    public static func parse(responseData: Data, encoding: String.Encoding) throws -> Self {
        guard let dict = try parseJSON(responseData: responseData) as? [String: Any] else {
            throw ParsingError.invalidData(description: "JSON structure is not a Dictionary")
        }
        
        guard let object:Self = Mapper().map(JSON: dict) else {
            throw ParsingError.invalidData(description: "JSON structure could not be mapped to \(self) class")
        }
        
        return object
    }
}
