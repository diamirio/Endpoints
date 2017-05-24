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

    @discardableResult
    func test<C: Call>(call: C, validateResult: ((DecodedResult<C.ResponseType>)->())?=nil) ->  URLSessionTask {
        let exp = test.expectation(description: "")
        let tsk = session.dataTask(for: call) { (result) in
            validateResult?(result)
            exp.fulfill()
        }
        tsk.debug = true
        let urlTsk = tsk.urlSessionTask

        urlTsk.resume()

        test.waitForExpectations(timeout: 10, handler: nil)

        return urlTsk
    }
}
