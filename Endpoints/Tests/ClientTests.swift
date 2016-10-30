//
//  EndpointTests.swift
//  EndpointTests
//
//  Created by Peter W on 10/10/2016.
//  Copyright © 2016 Tailored Apps. All rights reserved.
//

import XCTest
@testable import Endpoints

class ClientTests: XCTestCase {
    var tester: ClientTester<BaseClient>!
    
    override func setUp() {
        tester = ClientTester(test: self, client: BaseClient(baseURL: URL(string: "http://httpbin.org")!))
    }
    
    func testTimeoutError() {
        let request = DynamicRequest<Data>(.get, "delay/1", encode: { urlReq in
            var req = urlReq
            req.timeoutInterval = 0.5
            
            return req
        })
        
        tester.test(request: request) { result in
            self.tester.assert(result: result, isSuccess: false)
            XCTAssertNil(result.response?.statusCode)
            
            XCTAssertEqual(result.error?.localizedDescription, "The request timed out.")

            let error = result.error as! URLError
            XCTAssertEqual(error.code, URLError.timedOut)
        }
    }
    
    func testStatusError() {
        let request = DynamicRequest<Data>(.get, "status/400")
        
        tester.test(request: request) { result in
            self.tester.assert(result: result, isSuccess: false, status: 400)
            XCTAssertEqual(result.error?.localizedDescription, "bad request")
            
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
        
        tester.test(request: request) { result in
            self.tester.assert(result: result, isSuccess: true, status: 200)
        }
    }
    
    func testPostRawString() {
        let body = "body"
        let request = DynamicRequest<[String: Any]>(.post, "post", header: [ "Content-Type": "raw" ], body: body)
        
        tester.test(request: request) { result in
            self.tester.assert(result: result, isSuccess: true, status: 200)
            result.onSuccess { value in
                XCTAssertEqual(value["data"] as? String, body)
                
                if let headers = value["headers"] as? [String: String] {
                    XCTAssertEqual(headers["Content-Type"], "raw")
                } else {
                    XCTFail("headers not found")
                }
            }
        }
    }
    
    func testPostString() {
        //foundation urlrequest defaults to form encoding
        let body = "key=value"
        let request = DynamicRequest<[String: Any]>(.post, "post", body: body)
        
        tester.test(request: request) { result in
            self.tester.assert(result: result, isSuccess: true, status: 200)
            result.onSuccess { value in
                if let form = value["form"] as? [String: String] {
                    XCTAssertEqual(form["key"], "value")
                } else {
                    XCTFail("form not found")
                }
                
                if let headers = value["headers"] as? [String: String] {
                    XCTAssertEqual(headers["Content-Type"], "application/x-www-form-urlencoded")
                } else {
                    XCTFail("headers not found")
                }
            }
        }
    }
    
    func testPostFormEncodedBody() {
        let params = [ "key": "value" ]
        let body = FormEncodedBody(parameters: params)
        let request = DynamicRequest<[String: Any]>(.post, "post", body: body)
        
        tester.test(request: request) { result in
            self.tester.assert(result: result, isSuccess: true, status: 200)
            
            result.onSuccess { value in
                if let form = value["form"] as? [String: String] {
                    XCTAssertEqual(form, params)
                } else {
                    XCTFail("form not found")
                }
                
                if let headers = value["headers"] as? [String: String] {
                    XCTAssertEqual(headers["Content-Type"], "application/x-www-form-urlencoded")
                } else {
                    XCTFail("headers not found")
                }
            }
        }
    }
    
    func testPostJSONBody() {
        let params = [ "key": "value" ]
        let body = try! JSONEncodedBody(jsonObject: params)
        let request = DynamicRequest<[String: Any]>(.post, "post", body: body)
        
        tester.test(request: request) { result in
            self.tester.assert(result: result, isSuccess: true, status: 200)
            
            result.onSuccess { value in
                if let form = value["json"] as? [String: String] {
                    XCTAssertEqual(form, params)
                } else {
                    XCTFail("form not found")
                }
                
                if let headers = value["headers"] as? [String: String] {
                    XCTAssertEqual(headers["Content-Type"], "application/json")
                } else {
                    XCTFail("headers not found")
                }
            }
        }
    }
    
    func testGetString() {
        let request = DynamicRequest<String>(.get, "get", query: [ "inputParam" : "inputParamValue" ])
        
        tester.test(request: request) { result in
            self.tester.assert(result: result, isSuccess: true, status: 200)
            
            if let string = result.value {
                XCTAssertTrue(string.contains("inputParamValue"))
            }
        }
    }
    
    func testGetJSONDictionary() {
        let request = DynamicRequest<[String: Any]>(.get, "get", query: [ "inputParam" : "inputParamValue" ])
        
        tester.test(request: request) { result in
            self.tester.assert(result: result, isSuccess: true, status: 200)
            
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
        
        tester.test(request: request) { result in
            self.tester.assert(result: result, isSuccess: false, status: 200)
            
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
        
        tester.test(request: GetOutput(value: value)) { result in
            self.tester.assert(result: result)
            
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
        
        func encode(withBaseURL baseURL: URL) -> URLRequest {
            var req = encodeData(withBaseURL: baseURL)
            
            req.setValue(mime, forHTTPHeaderField: "Accept")
            
            return req
        }
    }
    
    func testCustomizedURLRequest() {
        let mime = "invalid"
        let req = CustomizedURLRequest(mime: mime)
        
        tester.test(request: req) { result in
            self.tester.assert(result: result)
            
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
        
        func validate(result: URLSessionTaskResult) throws {
            throw StatusCodeError.unacceptable(code: 0, reason: nil)
        }
    }
    
    func testValidatedRequest() {
        let mime = "application/json"
        let req = ValidatedRequest(mime: mime)
        
        tester.test(request: req) { result in
            self.tester.assert(result: result, isSuccess: false)
            
            XCTAssertEqual(result.response?.allHeaderFields["Mime"] as? String, mime)
        }
    }
}
