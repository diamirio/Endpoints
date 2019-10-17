import XCTest
import Endpoints
@testable import ExampleCore

class BinResultProvider: FakeResultProvider {
    func resultFor<C: Call>(call: C) -> URLSessionTaskResult {
        var result = URLSessionTaskResult(response: nil, data: Data(), error: nil)
        
        if let serverMessage = call as? ServerMessageRequest {
            result.response = FakeHTTPURLResponse(status: 300, header: [ "X-Error-Message" : serverMessage.message])
        }
        
        return result
    }
}

struct ServerMessageRequest: Call {
    typealias Parser = Data
    
    var message: String
    
    var request: URLRequestEncodable {
        return Request(.get, "get")
    }
}

class FakeClientTests: XCTestCase {
    var tester: ClientTester<BinClient>!
    
    override func setUp() {
        let client = BinClient()
        let session = FakeSession(with: client, resultProvider: BinResultProvider())
        tester = ClientTester(test: self, session: session)
    }
    
    func testErrorMessageValidation() {
        let msg = "error message"
        tester.test(call: ServerMessageRequest(message: msg)) { result in
            self.tester.assert(result: result, isSuccess: false, status: 300)
            
            XCTAssertEqual(result.error?.localizedDescription, msg)
        }
    }
}
