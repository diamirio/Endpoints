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
        if let fake = request as? FakeRequest {
            return fake.fakeResult()
        }
        fatalError()
    }
}

protocol FakeRequest {
    func fakeResult() -> URLSessionTaskResult
}

struct ServerMessageRequest: Request {
    typealias ResponseType = Data

    var method: HTTPMethod { return .get }
    var path: String? { return "get" }
    
    var message: String
}

extension ServerMessageRequest: FakeRequest {
    func fakeResult() -> URLSessionTaskResult {
        let resp = FakeHTTPURLResponse(status: 300, header: [ "X-Error-Message" : message])
        return URLSessionTaskResult(response: resp, data: Data(), error: nil)
    }
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
        tester.expectError(ServerMessageRequest(message: msg)) { error in
            switch error {
            case StatusCodeError.unacceptable(300, let reason):
                XCTAssertEqual(reason, msg)
                break
            default:
                XCTFail("wrong error: \(error)")
            }
            if let statusCodeError = error as? StatusCodeError {
                XCTAssertEqual(statusCodeError.localizedDescription, msg)
            }
            XCTAssertEqual(error.localizedDescription, msg)
        }
    }
}
