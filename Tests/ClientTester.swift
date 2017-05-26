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
    func test<C: Call>(call: C, validateResult: ((DecodedResult<C.DecodedType>)->())?=nil) ->  URLSessionTask {
        let exp = test.expectation(description: "")
        let tsk = session.dataTask(for: call) { (result) in
            validateResult?(result)
            exp.fulfill()
        }
        tsk.debug = true
        tsk.start()

        let urlSessionTask = tsk.activeURLSessionTask!
        test.waitForExpectations(timeout: 10, handler: nil)

        return urlSessionTask
    }
}

public class FakeHTTPURLResponse: HTTPURLResponse {
    let fakeTextEncodingName: String?

    public override var textEncodingName: String? {
        if let fakeTextEncodingName = fakeTextEncodingName {
            return fakeTextEncodingName
        }
        return fakeTextEncodingName
    }

    public init(status code: Int=200, header: Parameters?=nil, textEncodingName: String?=nil) {
        fakeTextEncodingName = textEncodingName
        super.init(url: URL(string: "http://127.0.0.1")!, statusCode: code, httpVersion: nil, headerFields: header)!
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
