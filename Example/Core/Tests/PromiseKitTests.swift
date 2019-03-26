import XCTest
import Endpoints
import PromiseKit
@testable import ExampleCore

class PromiseKitTests: XCTestCase {
    var session = PromiseSession(with: BinClient())
    
    func testSuccess() {
        let input = "inout"
        let exp = expectation(description: "")
        
        firstly {
            session.start(call: BinClient.GetOutput(value: input))
        }.done { value -> Void in
            XCTAssertEqual(input, value.value)
            exp.fulfill()
        }.catch { error in
            XCTFail("error \(error)")
            exp.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testFailure() {
        let exp = expectation(description: "")
        
        firstly {
            session.start(call: AnyCall<Data>(Request(.get, "status/400")))
        }.done { value -> Void in
            XCTFail("expected error \(value)")
            exp.fulfill()
        }.catch { error in
            print("error: \(error)")
            exp.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
}
