//
//  EndpointExampleTests.swift
//  EndpointExampleTests
//
//  Created by Peter W on 10/10/2016.
//  Copyright © 2016 Tailored Apps. All rights reserved.
//

import XCTest
import Endpoints
@testable import EndpointsExample

class BinAPITests: APITestCase {
    let input = "inout"
    
    override func setUp() {
        api = BinAPI()
        api.debugAll = true
    }
    
    func testGetOutputEndpointRequest() {
        test(endpoint: GetOutput(value: input)) { result in
            self.assert(result: result, isSuccess: true, status: 200)
        }
    }
    
    func testGetOutput() {
        test(endpoint: BinAPI.GetOutputValue, with: InputValue(value: input)) { result in
            self.assert(result: result, isSuccess: true, status: 200)
        }
    }
    
    func testGenericGetValue() {
        test(endpoint: BinAPI.GetOutputValue, with: InputValue(value: input)) { result in
            self.assert(result: result, isSuccess: true, status: 200)
        }
    }
    
    func testDynamicEndpoint() {
        test(endpoint: BinAPI.DynamicRequest, with: DynamicRequestData(query: ["value": input])) { result in
            self.assert(result: result, isSuccess: true, status: 200)
        }
    }
    
    func testGetOutputFunctional() {
        let exp = expectation(description: "")
        BinAPI().getOutput(for: input) { result in
            self.assert(result: result, isSuccess: true, status: 200)
            
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testGetOutputBuilder() {
        let exp = expectation(description: "")
        let api = BinAPI()
        api.start(request: api.outputRequest(with: input), for: BinAPI.GetOutputValue) { result in
            self.assert(result: result, isSuccess: true, status: 200)
            
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testGetOutputManual() {
        let exp = expectation(description: "")
        URLSession.shared.dataTask(with: BinAPI().outputRequest(with: input)) { data, response, error in
            do {
                let value = try OutputValue.parse(responseData: data, encoding: .utf8)
                
                XCTAssertNotNil(value)
            } catch {
                XCTFail("error: \(error)")
            }
            
            exp.fulfill()
        }.resume()
        
        waitForExpectations(timeout: 10, handler: nil)
    }
}
