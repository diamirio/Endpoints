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
    let api = API(baseURL: URL(string: "http://httpbin.org")!)
    
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
        let endpoint = DynamicEndpoint<DynamicRequestData, Data>(.get, "delay")
        let data = DynamicRequestData(dynamicPath: "1")
        
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
        let endpoint = DynamicEndpoint<DynamicRequestData, Data>(.get, "status")
        let data = DynamicRequestData(dynamicPath: "400")
        
        let exp = expectation(description: "")
        
        api.call(endpoint: endpoint, with: data) { result in
            XCTAssertNil(result.value)
            XCTAssertNotNil(result.error)
            XCTAssertTrue(result.isError)
            XCTAssertFalse(result.isSuccess)
            
            XCTAssertNotNil(result.response)
            XCTAssertEqual(result.response?.statusCode, 400)
            
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
    
    func testGetData() {
        let endpoint = DynamicEndpoint<DynamicRequestData, Data>(.get, "get")
        let data = DynamicRequestData()
        
        let exp = expectation(description: "")

        api.call(endpoint: endpoint, with: data) { result in
            XCTAssertNotNil(result.value)
            XCTAssertNil(result.error)
            XCTAssertFalse(result.isError)
            XCTAssertTrue(result.isSuccess)
            
            XCTAssertNotNil(result.response)
            XCTAssertEqual(result.response?.statusCode, 200)
            
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testGetString() {
        let endpoint = DynamicEndpoint<DynamicRequestData, String>(.get, "get")
        let data = DynamicRequestData(query: [ "inputParam" : "inputParamValue" ])
        
        let exp = expectation(description: "")
        
        api.call(endpoint: endpoint, with: data) { result in
            XCTAssertNotNil(result.value)
            XCTAssertNil(result.error)
            XCTAssertFalse(result.isError)
            XCTAssertTrue(result.isSuccess)
            
            XCTAssertNotNil(result.response)
            XCTAssertEqual(result.response?.statusCode, 200)
            
            if let string = result.value {
                XCTAssertTrue(string.contains("inputParamValue"))
            }
            
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testGetJSONDictionary() {
        let endpoint = DynamicEndpoint<DynamicRequestData, [String: Any]>(.get, "get")
        let data = DynamicRequestData(query: [ "inputParam" : "inputParamValue" ])
        
        let exp = expectation(description: "")
        
        api.call(endpoint: endpoint, with: data) { result in
            XCTAssertNotNil(result.value)
            XCTAssertNil(result.error)
            XCTAssertFalse(result.isError)
            XCTAssertTrue(result.isSuccess)
            
            XCTAssertNotNil(result.response)
            XCTAssertEqual(result.response?.statusCode, 200)
            
            if let jsonDict = result.value {
                let args = jsonDict["args"]
                XCTAssertNotNil(args)
                
                if let args = args {
                    XCTAssertTrue(args is Dictionary<String, String>)
                    
                    if let args = args as? Dictionary<String, String> {
                        let param = args["inputParam"]
                        XCTAssertNotNil(param)
                        
                        if let param = param {
                            XCTAssertEqual(param, "inputParamValue")
                        }
                    }
                }
            }
            
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testPostJSONArray() {
        let inputArray = [ "one", "two", "three" ]
        let arrayData = try! JSONSerialization.data(withJSONObject: inputArray, options: .prettyPrinted)
        let endpoint = DynamicEndpoint<DynamicRequestData, [String]>(.post, "post")
        let data = DynamicRequestData(body: arrayData)
        
        let exp = expectation(description: "")
        
        api.call(endpoint: endpoint, with: data) { result in
            XCTAssertNil(result.value)
            XCTAssertNotNil(result.error)
            XCTAssertTrue(result.isError)
            XCTAssertFalse(result.isSuccess)
            
            XCTAssertNotNil(result.response)
            XCTAssertEqual(result.response?.statusCode, 200)
            
            if let jsonArray = result.value {
                XCTAssertEqual(jsonArray, inputArray)
            }
            
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testFailJSONParsing() {
        let endpoint = DynamicEndpoint<DynamicRequestData, [String: Any]>(.get, "xml")
        let data = DynamicRequestData()
        
        let exp = expectation(description: "")
        api.call(endpoint: endpoint, with: data) { result in
            XCTAssertNil(result.value)
            XCTAssertNotNil(result.error)
            XCTAssertTrue(result.isError)
            XCTAssertFalse(result.isSuccess)
            
            XCTAssertNotNil(result.response)
            XCTAssertEqual(result.response?.statusCode, 200)
            
            if let error = result.error as? CocoaError {
                XCTAssertTrue(error.isPropertyListError)
                XCTAssertEqual(error.code, CocoaError.Code.propertyListReadCorrupt)
            } else {
                XCTFail("wrong error: \(result.error)")
            }
            
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    struct GetOutput: EndpointRequest {
        typealias Request = GetOutput
        typealias Response = [String: Any]
        
        let value: String
        
        var path: String? { return "get" }
        var method: EndpointMethod { return .get }
        
        var query: Parameters? {
            return [ "param" : value ]
        }
    }
    
    func testTypedEndpointRequest() {
        let value = "value"
        
        test(endpoint: GetOutput(value: value)) { result in
            if let jsonDict = result.value {
                let args = jsonDict["args"]
                XCTAssertNotNil(args)
                
                if let args = args {
                    XCTAssertTrue(args is Dictionary<String, String>)
                    
                    if let args = args as? Dictionary<String, String> {
                        let param = args["param"]
                        XCTAssertNotNil(param)
                        
                        if let param = param {
                            XCTAssertEqual(param, value)
                        }
                    }
                }
            }
        }
    }
}

extension EndpointTests {
    func test<E: Endpoint, R: RequestEncoder, P: ParsableResponse>(endpoint: E, with data: R?=nil, validateResult: ((Result<P>)->())?=nil) where E.Request == R, E.Response == P  {
        let exp = expectation(description: "")
        api.call(endpoint: endpoint, with: data, debug: true) { result in
            XCTAssertNil(result.error)
            XCTAssertNotNil(result.value)
            XCTAssertTrue(result.isSuccess)
            XCTAssertFalse(result.isError)
            
            validateResult?(result)
            
            exp.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
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
