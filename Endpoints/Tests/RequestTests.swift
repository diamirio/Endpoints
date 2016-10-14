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
        let base = "http://httpbin.org"
        let queryParams = [ "q": "Äin €uro", "a": "test" ]
        let encodedQueryString = "q=%C3%84in%20%E2%82%ACuro&a=test"
        let expectedUrlString = "http://httpbin.org/get?\(encodedQueryString)"
        
        var req = testRequestEncoding(baseUrl: base, path: "get", queryParams: queryParams)
        XCTAssertEqual(req.url?.absoluteString, expectedUrlString)
        
        req = testRequestEncoding(baseUrl: base, path: "/get", queryParams: queryParams)
        XCTAssertEqual(req.url?.absoluteString, expectedUrlString)
        
        req = testRequestEncoding(baseUrl: base, dynamicPath: "get")
        XCTAssertEqual(req.url?.absoluteString, "\(base)/get")
    }
    
    func testRequestEncoding(baseUrl: String, path: String?=nil, queryParams: [String: String]?=nil, dynamicPath: String?=nil ) -> URLRequest {
        let api = API(baseURL: URL(string: baseUrl)!)
        let endpoint = DynamicEndpoint<DynamicRequestData, Data>(.get, path)
        let requestData = DynamicRequestData(dynamicPath: dynamicPath, query: queryParams)
        
        let request = api.request(for: endpoint, with: requestData)
        
        let exp = expectation(description: "")
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            let httpResponse = response as! HTTPURLResponse
            XCTAssertNotNil(data)
            XCTAssertNil(error)
            XCTAssertEqual(httpResponse.statusCode, 200)
            
            exp.fulfill()
            }.resume()
        
        waitForExpectations(timeout: 10, handler: nil)
        
        return request
    }
}
