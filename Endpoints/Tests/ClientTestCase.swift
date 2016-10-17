//
//  APITestCase.swift
//  Endpoints
//
//  Created by Peter W on 14/10/2016.
//  Copyright © 2016 Tailored Apps. All rights reserved.
//

import Foundation
import XCTest
@testable import Endpoints

class ClientTestCase<C: Client>: XCTestCase {
    var client: C!
    
    func test<R: Request>(request: R, validateResult: ((Result<R.ResponseType.OutputType>)->())?=nil) {
        let exp = expectation(description: "")
        client.start(request: request) { result in
            validateResult?(result)
            
            exp.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func assert<P: ResponseParser>(result: Result<P>, isSuccess: Bool=true, status code: Int?=nil) {
        if isSuccess {
            XCTAssertNil(result.error)
            XCTAssertNotNil(result.value)
            XCTAssertTrue(result.isSuccess)
            XCTAssertFalse(result.isError)
        } else {
            XCTAssertNotNil(result.error)
            XCTAssertNil(result.value)
            XCTAssertFalse(result.isSuccess)
            XCTAssertTrue(result.isError)
        }
        
        if let code = code {
            XCTAssertEqual(result.response?.statusCode, code)
        }
    }
}
