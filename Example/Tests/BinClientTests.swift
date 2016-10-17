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

class BinClientTests: ClientTestCase<BinClient> {
    let input = "inout"
    
    override func setUp() {
        client = BinClient()
    }
    
    func testGetOutputRequest() {
        test(request: BinClient.GetOutput(value: input)) { result in
            self.assert(result: result, isSuccess: true, status: 200)
            
            XCTAssertEqual(self.input, result.value?.value)
        }
    }
}
