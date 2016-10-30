//
//  RequestTests.swift
//  Endpoints
//
//  Created by Peter W on 14/10/2016.
//  Copyright © 2016 Tailored Apps. All rights reserved.
//

import XCTest
@testable import Endpoints

class RequestTests: XCTestCase {
    func testRequestEncoding() {
        let base = "https://httpbin.org"
        let queryParams = [ "q": "Äin €uro", "a": "test" ]
        let encodedQueryString = "q=%C3%84in%20%E2%82%ACuro&a=test"
        let expectedUrlString = "https://httpbin.org/get?\(encodedQueryString)"
        
        var req = testRequestEncoding(baseUrl: base, path: "get", queryParams: queryParams)
        XCTAssertEqual(req.url?.absoluteString, expectedUrlString)
        
        req = testRequestEncoding(baseUrl: base, path: "/get", queryParams: queryParams)
        XCTAssertEqual(req.url?.absoluteString, expectedUrlString)
    }

}

extension RequestTests {
    func testRequestEncoding(baseUrl: String, path: String?=nil, queryParams: [String: String]?=nil) -> URLRequest {
        let client = BaseClient(baseURL: URL(string: baseUrl)!)
        let request = DynamicRequest<Data>(.get, path, query: queryParams)
        
        let urlRequest = client.encode(request: request)
        
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
