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
    }
    
    private func start<R: Request>(request: R) -> Task<R.ResponseType.OutputType> {
        let exp = test.expectation(description: "")
        
        return session.start(request: request).whenDone {
            exp.fulfill()
        }
    }
    
    @discardableResult
    func expectSuccess<R: Request>(_ request: R, onSuccess: @escaping (R.ResponseType.OutputType)->()) -> Task<R.ResponseType.OutputType> {
        let t = start(request: request).onError { error in
            XCTFail("unexpected error: \(error.localizedDescription)")
        }.onSuccess(block: onSuccess)
        
        test.waitForExpectations(timeout: 10, handler: nil)
        
        return t
    }
    
    @discardableResult
    func expectError<R: Request>(_ request: R, onError: @escaping (Error)->()) -> Task<R.ResponseType.OutputType> {
        let t = start(request: request).onSuccess { value in
            XCTFail("unexpected success with value: \(value)")
        }.onError(block: onError)
        
        test.waitForExpectations(timeout: 10, handler: nil)
        
        return t
    }
}
