import XCTest
import Unbox
import Endpoints
@testable import ExampleCore

class EndpointUnboxTests: XCTestCase {
    var tester: ClientTester<AnyClient>!
    
    override func setUp() {
        tester = ClientTester(test: self, client: AnyClient(baseURL: URL(string: "https://httpbin.org")!))
    }

    struct UnboxTest: Unboxable, ResponseDecodable {
        let x: String

        init(unboxer: Unboxer) throws {
            x = try unboxer.unbox(key: "x")
        }
    }

    func testUnboxableParsing() {
        let json = [ "x": "a" ]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        let parsed = try! UnboxTest.responseDecoder(HTTPURLResponse(), jsonData)
        
        XCTAssertEqual(parsed.x, "a")
    }
    
    func testUnboxableArrayParsing() {
        let json = [[ "x": "a" ], [ "x": "z"]]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        let parsed = try! [UnboxTest].decodeUnboxableArray(response: HTTPURLResponse(), data: jsonData)
        
        XCTAssertEqual(parsed.count, 2)
        XCTAssertEqual(parsed.first!.x, "a")
    }
}
