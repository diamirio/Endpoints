//
//  APITestCase.swift
//  Endpoints
//
//  Created by Peter W on 14/10/2016.
//  Copyright © 2016 Tailored Apps. All rights reserved.
//

import Foundation
import XCTest
import Endpoints

class ClientTester<C: Client> {
    var session: Session<C>
    let test: XCTestCase
    
    convenience init(test: XCTestCase, client: C) {
        self.init(test: test, session: Session(with: client))
    }
    
    init(test: XCTestCase, session: Session<C>) {
        self.test = test
        self.session = session
        session.debug = true
    }
    
    func test<R: Request>(request: R, validateResult: ((Result<R.ResponseType.OutputType>)->())?=nil) {
        let exp = test.expectation(description: "")
        session.start(request: request) { result in
            validateResult?(result)
            
            exp.fulfill()
        }
        test.waitForExpectations(timeout: 30, handler: nil)
    }
    
    func assert<P: ResponseParser>(result: Result<P>, isSuccess: Bool=true, status code: Int?=nil) {
        if isSuccess {
            XCTAssertNil(result.error)
            XCTAssertNotNil(result.value)
        } else {
            XCTAssertNotNil(result.error)
            XCTAssertNil(result.value)
        }
        
        if let code = code {
            XCTAssertEqual(result.response?.statusCode, code)
        }
    }
}
