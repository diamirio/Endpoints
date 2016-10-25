//
//  EndpointExampleTests.swift
//  EndpointExampleTests
//
//  Created by Peter W on 10/10/2016.
//  Copyright © 2016 Tailored Apps. All rights reserved.
//

import XCTest
@testable import Endpoints
@testable import Example

class BinResultProvider: FakeResultProvider {
    func resultFor<R: Request>(request: R) -> URLSessionTaskResult {
        var result = URLSessionTaskResult(response: nil, data: Data(), error: nil)
        
        if let serverMessage = request as? ServerMessageRequest {
            result.response = FakeHTTPURLResponse(status: 300, header: [ "X-Error-Message" : serverMessage.message])
        }
        
        return result
    }
}

struct ServerMessageRequest: Request {
    typealias ResponseType = Data

    var method: HTTPMethod { return .get }
    var path: String? { return "get" }
    
    var message: String
}

class MockClientTests: XCTestCase {
    var tester: ClientTester<BinClient>!
    
    override func setUp() {
        let client = BinClient()
        let session = FakeSession(with: client, resultProvider: BinResultProvider())
        tester = ClientTester(test: self, session: session)
    }
    
    func testErrorMessageValidation() {
        let msg = "error message"
        tester.test(request: ServerMessageRequest(message: msg)) { result in
            self.tester.assert(result: result, isSuccess: false, status: 300)
            
            XCTAssertEqual(result.error?.localizedDescription, msg)
        }
    }
}
