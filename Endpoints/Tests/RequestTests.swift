import XCTest
@testable import Endpoints

class RequestTests: XCTestCase {    
    func testRelativeRequestEncoding() {
        let base = "https://httpbin.org/"
        let queryParams = [ "q": "Äin €uro", "a": "test" ]
        let encodedQueryString = "q=%C3%84in%20%E2%82%ACuro&a=test"
        let expectedUrlString = "https://httpbin.org/get?\(encodedQueryString)"
        
        var req = testRequestEncoding(baseUrl: base, path: "get", queryParams: queryParams)
        XCTAssertEqual(req.url?.absoluteString, expectedUrlString)
        
        req = testRequestEncoding(baseUrl: base + "get", queryParams: queryParams)
        XCTAssertEqual(req.url?.absoluteString, expectedUrlString)
    }
    
    func testHATEOASRequest() {
        let absoluteURL = URL(string: "https://httpbin.org/get?x=z")!
        let body = try! JSONEncodedBody(jsonObject: [ "x": "y" ])
        
        var req = Request(.get, "post", query: ["x": "y"], header: [ "x": "y" ], body: body)
        req.url = absoluteURL
        let c = AnyCall<Data>(req)
        
        let urlReq = AnyClient(baseURL: URL(string: "http://google.com")!).encode(call: c)
        
        XCTAssertEqual(urlReq.url, absoluteURL)
        XCTAssertEqual(urlReq.httpBody, body.requestData)
        XCTAssertEqual(urlReq.allHTTPHeaderFields?["Content-Type"], "application/json")
        XCTAssertEqual(urlReq.allHTTPHeaderFields?["x"], "y")
    }
}

extension RequestTests {
    func testRequestEncoding(baseUrl: String, path: String?=nil, queryParams: [String: String]?=nil) -> URLRequest {
        let request = Request(.get, path, query: queryParams)
        let call = AnyCall<Data>(request)
        let client = AnyClient(baseURL: URL(string: baseUrl)!)
        let urlRequest = client.encode(call: call)
        
        let exp = expectation(description: "")
        URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            let httpResponse = response as! HTTPURLResponse
            XCTAssertNotNil(data)
            XCTAssertNil(error)
            XCTAssertEqual(httpResponse.statusCode, 200)
            
            exp.fulfill()
        }.resume()
        
        waitForExpectations(timeout: 10, handler: nil)
        
        return urlRequest
    }
}
