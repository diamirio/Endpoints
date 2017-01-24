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
        var search = GiphyClient.Search(query: "cat", pageSize: 10, page: 1)
        var totalCount: Int?
        
        tester.test(call: search) { result in
            self.tester.assert(result: result)
            
            result.onSuccess { value in
                XCTAssertEqual(value.images.count, 10)
                XCTAssertEqual(value.pagination.count, 10)
                XCTAssertEqual(value.pagination.offset, 10)
                XCTAssertFalse(value.pagination.isLastPage)
                
                totalCount = value.pagination.totalCount
            }
        }
        
        guard let total = totalCount else {
            //first call failed
            return
        }
        
        search.page = Int(floor(Double(total) / 10.0))
        
        tester.test(call: search) { result in
            self.tester.assert(result: result)
            
            result.onSuccess { value in
                XCTAssertTrue(value.pagination.isLastPage)
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
