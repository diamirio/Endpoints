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
        
        tester.test(request: request) { result in
            self.tester.assert(result: result)
            
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
        
        let request = DynamicRequest<String>(.post, "post", body: try! JSONEncodedBody(mappable: jsonBody))
        
        tester.test(request: request) { result in
            self.tester.assert(result: result)
            
            if let string = result.value {
                XCTAssertTrue(string.contains(jsonBody.value))
            }
        }
    }
    
    struct PostJSONRequest: Request {
        typealias ResponseType = String
        
        var method: HTTPMethod { return .post }
        var path: String? { return "post" }
        
        var object: RequestObject
        
        var body: Body? {
            return try! JSONEncodedBody(mappable: object)
        }
    }
    
    func testPostJSONDataTyped() {
        var jsonBody = RequestObject()
        jsonBody.value = "zapzarap"
        
        tester.test(request: PostJSONRequest(object: jsonBody)) { result in
            self.tester.assert(result: result)
            
            if let string = result.value {
                XCTAssertTrue(string.contains(jsonBody.value))
            }
        }
    }
}
