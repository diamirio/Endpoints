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

class EndpointMapperTests: XCTestCase {
    var tester: ClientTester<BaseClient>!
    
    override func setUp() {
        tester = ClientTester(test: self, client: BaseClient(baseURL: URL(string: "https://httpbin.org")!))
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
        let request = DynamicRequest<ResponseObject>(.get, "get", query: [ "input": value ])
        
        tester.expectSuccess(request) { result in
            XCTAssertEqual(result.value, value)
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
        
        let request = DynamicRequest<String>(.post, "post", body: jsonBody.toData())
        
        tester.expectSuccess(request) { string in
            XCTAssertTrue(string.contains(jsonBody.value))
        }
    }

    struct PostJSONRequest: Request {
        typealias ResponseType = String
        
        var method: HTTPMethod { return .post }
        var path: String? { return "post" }
        
        var object: RequestObject
        
        var body: Data? {
            return object.toData()
        }
    }
    
    func testPostJSONDataTyped() {
        var jsonBody = RequestObject()
        jsonBody.value = "zapzarap"
        
        tester.expectSuccess(PostJSONRequest(object: jsonBody)) { string in
            XCTAssertTrue(string.contains(jsonBody.value))
        }
    }
    
    struct ConvenientPostJSONRequest: MappableRequest {
        typealias MappableType = RequestObject
        typealias ResponseType = String
        
        var mappable: RequestObject
        var path: String? { return "post" }
    }
    
    func testPostJSONDataTypedConvenient() {
        var jsonBody = RequestObject()
        jsonBody.value = "zapzarap"
        
        tester.expectSuccess(ConvenientPostJSONRequest(mappable: jsonBody)) { string in
            XCTAssertTrue(string.contains(jsonBody.value))
        }
    }
}
