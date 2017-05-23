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
    
    func test<C: Call>(call: C, validateResult: ((Result<C.ResponseType>)->())?=nil) {
        let exp = test.expectation(description: "")
        session.start(call: call) { result in
            validateResult?(result)
            
            exp.fulfill()
        }
        test.waitForExpectations(timeout: 30, handler: nil)
    }
    
    func assert<D: ResponseDecodable>(result: Result<D>, isSuccess: Bool=true, status code: Int?=nil) {
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
