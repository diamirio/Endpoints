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
    
    func test<C: Call>(call: C, validateResult: ((Result<C.Parser.OutputType>) -> Void)? = nil) {
        let exp = test.expectation(description: "")
        session.start(call: call) { result in
            validateResult?(result)
            
            exp.fulfill()
        }
        test.waitForExpectations(timeout: 30, handler: nil)
    }
    
#if compiler(>=5.5) && canImport(_Concurrency)
    
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0,  *)
    func testAsync<C: Call>(call: C) async throws -> (C.Parser.OutputType, HTTPURLResponse) {
        return try await session.start(call: call)
    }
    
#endif
    
    func assert<Output>(result: Result<Output>, isSuccess: Bool=true, status code: Int?=nil) {
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
