import XCTest
import Endpoints
import Unbox
@testable import ExampleCore

class GiphyClientTests: XCTestCase {
    var tester: ClientTester<GiphyClient>!
    
    override func setUp() {
        tester = ClientTester(test: self, client: GiphyClient())
    }
    
    func testSearch() {
        tester.test(call: GiphyClient.Search(query: "cat", pageSize: 10, page: 0)) { result in
            self.tester.assert(result: result)
            
            result.onSuccess { value in
                XCTAssertEqual(value.images.count, 10)
            }
        }
    }
    
    func testErrorHandling() {
        tester.session.client.apiKey = "WRONG!"
        
        tester.test(call: GiphyClient.Search(query: "cat", pageSize: 10, page: 0)) { result in
            self.tester.assert(result: result, isSuccess: false)
            
            result.onError { error in
                print("error: \(error)")
            }
        }
    }
}
