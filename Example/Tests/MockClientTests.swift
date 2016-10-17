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

class MockClient: BinClient {
    func start<R : Request>(request: R, completion: @escaping (Result<R.ResponseType.OutputType>) -> ()) -> URLSessionDataTask {
        let sessionResult = resultFor(request: request)
        let result = transform(sessionResult: sessionResult, for: request)
        
        DispatchQueue.main.async {
            completion(result)
        }
        
        return URLSession.shared.dataTask(with: encode(request: request))
    }
    
    func resultFor<R: Request>(request: R) -> SessionTaskResult {
        let url = self.encode(request: request).url!
        var result = SessionTaskResult(response: nil, data: Data(), error: nil)
        
        if let serverMessage = request as? ServerMessageRequest {
            result.response = HTTPURLResponse(url: url, statusCode: 300, httpVersion: nil, headerFields: [ "X-Error-Message" : serverMessage.message])
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

class MockClientTests: ClientTestCase<MockClient> {
    override func setUp() {
        client = MockClient()
    }
    
    func testErrorMessageValidation() {
        let msg = "error message"
        test(request: ServerMessageRequest(message: msg)) { result in
            self.assert(result: result, isSuccess: false, status: 299)
        }
    }
}
