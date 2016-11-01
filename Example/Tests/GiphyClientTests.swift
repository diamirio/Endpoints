import XCTest
import Endpoints
import Unbox
@testable import Example

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
    
    struct UnboxTest: Unboxable {
        let x: String
        
        init(unboxer: Unboxer) throws {
            x = try unboxer.unbox(key: "x")
        }
    }

    func testUnboxableArrayParsing() {
        let json = [ [ "x": "a" ], [ "x": "z"]]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        let parsed = try! UnboxableArray<UnboxTest>.parse(data: jsonData, encoding: .utf8)
        
        XCTAssertEqual(parsed.count, 2)
        XCTAssertEqual(parsed.first!.x, "a")
    }
}

class UnboxableArray<Element: Unboxable>: DataParser {
    typealias OutputType = [Element]
    
    static func parse(data: Data, encoding: String.Encoding) throws -> OutputType {
        return try unbox(data: data)
    }
}
