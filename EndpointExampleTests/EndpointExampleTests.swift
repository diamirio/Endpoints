//
//  EndpointExampleTests.swift
//  EndpointExampleTests
//
//  Created by Peter W on 10/10/2016.
//  Copyright © 2016 Tailored Apps. All rights reserved.
//

import XCTest
@testable import EndpointExample

class EndpointExampleTests: XCTestCase {

    func testGetOutput() {
        let input = "inout"
        let exp = expectation(description: "")
        BinAPI().call(endpoint: BinAPI.GetOutputValue, with: InputValue(value: input)) { result in
            XCTAssertNil(result.error)
            XCTAssertNotNil(result.value)
            
            if let output = result.value {
                XCTAssertEqual(output.value, input)
            }
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
}
