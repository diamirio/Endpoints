import XCTest
import Endpoints
import Unbox
@testable import Example

class GithubClientTests: XCTestCase {
    var tester: ClientTester<GithubClient>!
    
    override func setUp() {
        let client = GithubClient()
        //client.user = BasicAuthorization(user: "", password: "")
        tester = ClientTester(test: self, client: client)
    }
    
    func testSearchRepositories() {
        let search = GithubClient.SearchRepositories(endpoint: .query("swift", sort: .stars))
        
        tester.test(call: search) { result in
            self.tester.assert(result: result)
            
            result.onSuccess { value in
                XCTAssertTrue(value.totalCount > 0)
                XCTAssertTrue(value.totalCount >= value.repositories.count)
                XCTAssertNotNil(value.nextPage)
            }
        }
    }
}
