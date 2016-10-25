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
        tester.test(request: BinClient.GetOutput(value: input)) { result in
            self.tester.assert(result: result, isSuccess: true, status: 200)
            
            XCTAssertEqual(self.input, result.value?.value)
        }
    }
}
