//
//  EndpointExampleTests.swift
//  EndpointExampleTests
//
//  Created by Peter W on 10/10/2016.
//  Copyright © 2016 Tailored Apps. All rights reserved.
//

import XCTest
import Endpoint
@testable import EndpointExample

class BinAPITests: XCTestCase {
    let input = "inout"
    
    func testGetOutputEndpointRequest() {
        test(endpoint: BinAPI.GetOutput(value: input)) { result in
            self.checkOutput(result: result)
        }
    }
    
    func testGetOutput() {
        let exp = expectation(description: "")
        BinAPI().call(endpoint: BinAPI.GetOutputValue, with: InputValue(value: input)) { result in
            self.checkOutput(result: result)
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testGenericGetValue() {
        test(endpoint: BinAPI.GetOutputValue, with: InputValue(value: input)) { result in
            self.checkOutput(result: result)
        }
    }
    
    func testDynamicEndpoint() {
        test(endpoint: BinAPI.DynamicRequest, with: DynamicRequestData(query: ["value": input])) { result in
            self.checkOutput(result: result)
        }
    }
    
    func testGetOutputFunctional() {
        let exp = expectation(description: "")
        BinAPI().getOutput(for: input) { result in
            self.checkOutput(result: result)
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testGetOutputBuilder() {
        let exp = expectation(description: "")
        let api = BinAPI()
        api.start(request: api.outputRequest(with: input), for: BinAPI.GetOutputValue) { result in
            self.checkOutput(result: result)
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

extension BinAPITests {
    func test<E: Endpoint, R: RequestEncoder, P: ParsableResponse>(endpoint: E, with data: R?=nil, validateResult: ((Result<P>)->())?=nil) where E.RequestType == R, E.ResponseType == P {
        let exp = expectation(description: "")
        BinAPI().call(endpoint: endpoint, with: data, debug: true) { result in
            if let error = result.error {
                dump(error)
            }
            XCTAssertNil(result.error)
            XCTAssertNotNil(result.value)
            XCTAssertTrue(result.isSuccess)
            XCTAssertFalse(result.isError)
            
            validateResult?(result)
            
            exp.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func checkOutput(result: Result<OutputValue>) {
        XCTAssertNil(result.error)
        XCTAssertNotNil(result.value)
        XCTAssertTrue(result.isSuccess)
        XCTAssertFalse(result.isError)
        
        if let output = result.value {
            XCTAssertEqual(output.value, input)
        }
    }
}
