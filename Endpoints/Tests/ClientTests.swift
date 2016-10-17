//
//  EndpointTests.swift
//  EndpointTests
//
//  Created by Peter W on 10/10/2016.
//  Copyright © 2016 Tailored Apps. All rights reserved.
//

import XCTest
@testable import Endpoints

class ClientTests: ClientTestCase<BaseClient> {
    override func setUp() {
        client = BaseClient(baseURL: URL(string: "http://httpbin.org")!)
    }
    
    func testTimeoutError() {
        let request = DynamicRequest<Data>(.get, "delay/1", encode: { urlReq in
            var req = urlReq
            req.timeoutInterval = 0.5
            
            return req
        })
        
        test(request: request) { result in
            self.assert(result: result, isSuccess: false)
            XCTAssertNil(result.response?.statusCode)
            
            let error = result.error as! URLError
            XCTAssertEqual(error.code, URLError.timedOut)
        }
    }
    
    func testStatusError() {
        let request = DynamicRequest<Data>(.get, "status/400")
        
        test(request: request) { result in
            self.assert(result: result, isSuccess: false, status: 400)
            
            if let error = result.error as? StatusCodeError {
                switch error {
                case .unacceptable(400, _):
                    print("code is ok")
                default:
                    XCTFail("wrong error: \(error)")
                }
            } else {
                XCTFail("wrong error: \(result.error)")
            }
        }
    }
    
    func testGetData() {
        let request = DynamicRequest<Data>(.get, "get")
        
        test(request: request) { result in
            self.assert(result: result, isSuccess: true, status: 200)
        }
    }
    
    func testGetString() {
        let request = DynamicRequest<String>(.get, "get", query: [ "inputParam" : "inputParamValue" ])
        
        test(request: request) { result in
            self.assert(result: result, isSuccess: true, status: 200)
            
            if let string = result.value {
                XCTAssertTrue(string.contains("inputParamValue"))
            }
        }
    }
    
    func testWrapperRequest() {
        var validateCalled = false
        let endpoint = DynamicRequest<String>(.get, "get", encode: nil) { result in
            validateCalled = true
        }
        let data = DynamicRequest<Data>(.post, "ignored", query: [ "inputParam" : "inputParamValue" ])
        let wrapper = EndpointRequest(endpoint: endpoint, requestEncoder: data)
        
        test(request: wrapper) { result in
            self.assert(result: result)
            
            XCTAssertTrue(validateCalled)
            if let string = result.value {
                XCTAssertTrue(string.contains("inputParamValue"))
            }
        }
    }
    
    func testGetJSONDictionary() {
        let request = DynamicRequest<[String: Any]>(.get, "get", query: [ "inputParam" : "inputParamValue" ])
        
        test(request: request) { result in
            self.assert(result: result, isSuccess: true, status: 200)
            
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
        }
    }
    
    func testParseJSONArray() {
        let inputArray = [ "one", "two", "three" ]
        let arrayData = try! JSONSerialization.data(withJSONObject: inputArray, options: .prettyPrinted)

        let parsedObject = try! DynamicRequest<[String]>.ResponseType.parse(responseData: arrayData, encoding: .utf8)
        
        XCTAssertEqual(inputArray, parsedObject)
    }
    
    func testFailJSONParsing() {
        let request = DynamicRequest<[String: Any]>(.get, "xml")
        
        test(request: request) { result in
            self.assert(result: result, isSuccess: false, status: 200)
            
            if let error = result.error as? CocoaError {
                XCTAssertTrue(error.isPropertyListError)
                XCTAssertEqual(error.code, CocoaError.Code.propertyListReadCorrupt)
            } else {
                XCTFail("wrong error: \(result.error)")
            }
        }
    }
    
    struct GetOutput: Request {
        typealias ResponseType = [String: Any]
        
        let value: String
        
        var path: String? { return "get" }
        var method: HTTPMethod { return .get }
        
        var query: Parameters? {
            return [ "param" : value ]
        }
    }
    
    func testTypedRequest() {
        let value = "value"
        
        test(request: GetOutput(value: value)) { result in
            self.assert(result: result)
            
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
    
    struct CustomizedURLRequest: Request {
        typealias ResponseType = [String: Any]

        var path: String? { return "headers" }
        var method: HTTPMethod { return .get }
        
        var mime: String
        
        func encode(request: URLRequest) -> URLRequest {
            var req = request
            
            req.setValue("invalid", forHTTPHeaderField: "Accept")
            
            return req
        }
    }
    
    func testCustomizedURLRequest() {
        let mime = "invalid"
        let req = CustomizedURLRequest(mime: mime)
        
        test(request: req) { result in
            self.assert(result: result)
            
            if let headers = result.value?["headers"] as? [String: String] {
                XCTAssertEqual(headers["Accept"], mime)
            } else {
                XCTFail("no headers")
            }
        }
    }
    
    struct ValidatedRequest: Request {
        typealias ResponseType = [String: Any]
        
        var path: String? { return "response-headers" }
        var method: HTTPMethod { return .get }
        var query: Parameters? { return [ "Mime": mime ] }
        
        var mime: String
        
        func validate(result: SessionTaskResult) throws {
            throw StatusCodeError.unacceptable(code: 0, reason: nil)
        }
    }
    
    func testValidatedRequest() {
        let mime = "application/json"
        let req = ValidatedRequest(mime: mime)
        
        test(request: req) { result in
            self.assert(result: result, isSuccess: false)
            
            XCTAssertEqual(result.response?.allHeaderFields["Mime"] as? String, mime)
        }
    }
}
