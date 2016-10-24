//
//  EndpointExampleTests.swift
//  EndpointExampleTests
//
//  Created by Peter W on 10/10/2016.
//  Copyright © 2016 Tailored Apps. All rights reserved.
//

import XCTest
import Endpoints
@testable import Example

class BinClientTests: XCTestCase {
    let input = "inout"
    
    var tester: ClientTester<BinClient>!
    
    override func setUp() {
        tester = ClientTester(test: self, client: BinClient())
    }
    
    func testGetOutputRequest() {
        let t = tester.expectSuccess(BinClient.GetOutput(value: input)) { value in
            XCTAssertEqual(self.input, value.value)
        }
        XCTAssertEqual(t.statusCode, 200)
    }
}
