//
//  EndpointTests.swift
//  EndpointTests
//
//  Created by Peter W on 10/10/2016.
//  Copyright © 2016 Tailored Apps. All rights reserved.
//

import XCTest
@testable import Endpoint

class EndpointTests: XCTestCase {
    let api = HTTPAPI(baseURL: URL(string: "http://httpbin.org")!)
    
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
    
    func testTimeoutError() {
        let endpoint = Endpoint<RequestData, Data>(method: .get, path: "delay")
        let data = RequestData(dynamicPath: "1",
                                       queryParameters: nil,
                                       headers: nil,
                                       body: nil)
        
        let exp = expectation(description: "")
        var req = api.request(for: endpoint, with: data)
        req.timeoutInterval = 0.5
        
        api.start(request: req, responseType: Data.self) { result in
            XCTAssertNil(result.value)
            XCTAssertNotNil(result.error)
            XCTAssertTrue(result.isError)
            XCTAssertFalse(result.isSuccess)
            
            XCTAssertNil(result.response)
            XCTAssertNil(result.response?.statusCode)
            
            let error = result.error as! URLError
            XCTAssertEqual(error.code, URLError.timedOut)
            
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testStatusError() {
        let endpoint = Endpoint<RequestData, Data>(method: .get, path: "status")
        let data = RequestData(dynamicPath: "400",
                               queryParameters: nil,
                               headers: nil,
                               body: nil)
        
        let exp = expectation(description: "")
        
        api.call(endpoint: endpoint, with: data) { result in
            XCTAssertNil(result.value)
            XCTAssertNotNil(result.error)
            XCTAssertTrue(result.isError)
            XCTAssertFalse(result.isSuccess)
            
            XCTAssertNotNil(result.response)
            XCTAssertNotNil(result.response?.statusCode)
            
            if let error = result.error as? APIError {
                switch error {
                case .unacceptableStatus:
                    print("got expected error: \(error)")
                default:
                    XCTFail("wrong error type \(error)")
                }
            } else {
                XCTFail("wrong error: \(result.error)")
            }
            
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
}

extension EndpointTests {
    func testRequestEncoding(baseUrl: String, path: String?=nil, queryParams: [String: String]?=nil, dynamicPath: String?=nil ) -> URLRequest {
        let api = HTTPAPI(baseURL: URL(string: baseUrl)!)
        let endpoint = Endpoint<RequestData, Data>(method: .get, path: path)
        let requestData = RequestData(dynamicPath: dynamicPath,
                                       queryParameters: queryParams,
                                       headers: nil,
                                       body: nil)
        
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
