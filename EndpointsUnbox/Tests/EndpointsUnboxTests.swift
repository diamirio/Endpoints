import XCTest
import Unbox
import Endpoints
@testable import EndpointsUnbox

class EndpointUnboxTests: XCTestCase {
    var tester: ClientTester<AnyClient>!
    
    override func setUp() {
        tester = ClientTester(test: self, client: AnyClient(baseURL: URL(string: "https://httpbin.org")!))
    }
    
    struct UnboxTest: UnboxableParser {
        let x: String
        
        init(unboxer: Unboxer) throws {
            x = try unboxer.unbox(key: "x")
        }
    }
    
    func testUnboxableParsing() {
        let json = [ "x": "a" ]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        let parsed = try! UnboxTest.parse(data: jsonData, encoding: .utf8)
        
        XCTAssertEqual(parsed.x, "a")
    }
    
    func testUnboxableArrayParsing() {
        let json = [ [ "x": "a" ], [ "x": "z"]]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        let parsed = try! UnboxableArray<UnboxTest>.parse(data: jsonData, encoding: .utf8)
        
        XCTAssertEqual(parsed.count, 2)
        XCTAssertEqual(parsed.first!.x, "a")
    }
}
