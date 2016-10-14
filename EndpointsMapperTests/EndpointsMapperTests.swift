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
    
    struct RequestObject: Mappable {
        var value = ""
        
        init() {}
        init?(map: Map) {}
        mutating func mapping(map: Map){
            value <- map["value"]
        }
    }
    
    func testPostJSONDataDynamic() {
        var jsonBody = RequestObject()
        jsonBody.value = "zapzarap"
        
        let data = try! DynamicRequestData(mappable: jsonBody)
        let ep = DynamicEndpoint<DynamicRequestData, String>(.post, "post")
        
        test(endpoint: ep, with: data) { result in
            self.assert(result: result)
            
            if let string = result.value {
                XCTAssertTrue(string.contains(jsonBody.value))
            }
        }
    }
    
    struct PostJSONEndpointRequest: EndpointRequest {
        typealias RequestType = PostJSONEndpointRequest
        typealias ResponseType = String
        
        var method: HTTPMethod { return .post }
        var path: String? { return "post" }
        
        var object: RequestObject
        
        var body: Data? {
            return try! object.toData()
        }
    }
    
    func testPostJSONDataTyped() {
        var jsonBody = RequestObject()
        jsonBody.value = "zapzarap"
        
        test(endpoint: PostJSONEndpointRequest(object: jsonBody)) { result in
            self.assert(result: result)
            
            if let string = result.value {
                XCTAssertTrue(string.contains(jsonBody.value))
            }
        }
    }
    
    struct ConvenientPostJSONEndpointRequest: MappableEndpointRequest {
        typealias MappableType = RequestObject
        typealias RequestType = ConvenientPostJSONEndpointRequest
        typealias ResponseType = String
        
        var mappable: RequestObject
        var path: String? { return "post" }
    }
    
    func testPostJSONDataTypedConvenient() {
        var jsonBody = RequestObject()
        jsonBody.value = "zapzarap"
        
        test(endpoint: ConvenientPostJSONEndpointRequest(mappable: jsonBody)) { result in
            self.assert(result: result)
            
            if let string = result.value {
                XCTAssertTrue(string.contains(jsonBody.value))
            }
        }
    }
}
