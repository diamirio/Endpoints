import XCTest
import ObjectMapper
import Endpoints
@testable import EndpointsMapper

class EndpointMapperTests: XCTestCase {
    var tester: ClientTester<BaseClient>!
    
    override func setUp() {
        tester = ClientTester(test: self, client: BaseClient(baseURL: URL(string: "https://httpbin.org")!))
    }
    
    struct ResponseObject: MappableResponse {
        var value = ""
        
        init?(map: Map) {}
        mutating func mapping(map: Map){
            value <- map["args.input.value"]
        }
    }
    
    func testResponseParsing() {
        let value = "value"
        let c = DynamicCall<ResponseObject>(Request(.get, "get", query: [ "input": value ]))
        
        tester.test(call: c) { result in
            self.tester.assert(result: result)
            
            XCTAssertEqual(result.value?.value, value)
        }
    }
    
    struct RequestObject: Mappable {
        var value = ""
        
        init() {}
        init?(map: Map) {}
        mutating func mapping(map: Map){
            value <- map["value"]
        }
    }
    
    func testPostJSONDataDynamic() {
        var jsonBody = RequestObject()
        jsonBody.value = "zapzarap"
        
        let c = DynamicCall<String>(Request(.post, "post", body: try! JSONEncodedBody(mappable: jsonBody)))
        
        tester.test(call: c) { result in
            self.tester.assert(result: result)
            
            if let string = result.value {
                XCTAssertTrue(string.contains(jsonBody.value))
            }
        }
    }
    
    struct PostJSONRequest: Call {
        typealias ResponseType = String
        var object: RequestObject
        
        var request: Request {
            return Request(.post, "post", body: try! JSONEncodedBody(mappable: object))
        }
    }
    
    func testPostJSONDataTyped() {
        var jsonBody = RequestObject()
        jsonBody.value = "zapzarap"
        
        tester.test(call: PostJSONRequest(object: jsonBody)) { result in
            self.tester.assert(result: result)
            
            if let string = result.value {
                XCTAssertTrue(string.contains(jsonBody.value))
            }
        }
    }
}
