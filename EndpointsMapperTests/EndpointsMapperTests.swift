//
//  EndpointMapperTests.swift
//  EndpointMapperTests
//
//  Created by Peter W on 13/10/2016.
//  Copyright © 2016 Tailored Apps. All rights reserved.
//

import XCTest
import ObjectMapper
import Endpoints
@testable import EndpointsMapper

class EndpointMapperTests: APITestCase {
    override func setUp() {
        api = API(baseURL: URL(string: "https://httpbin.org")!)
        api.debugAll = true
    }
    
    struct ResponseObject: MappableResponse {
        var value = ""
        
        init?(map: Map) {}
        mutating func mapping(map: Map){
            value <- map["args.input.value"]
        }
    }
    
    func testResponseParsing() {
        let value = "value"
        let ep = DynamicEndpoint<DynamicRequestData, ResponseObject>(.get, "get")
        let data = DynamicRequestData(query: [ "input": value ])
        
        test(endpoint: ep, with: data) { result in
            self.assert(result: result)
            
            XCTAssertEqual(result.value?.value, value)
        }
    }
}
