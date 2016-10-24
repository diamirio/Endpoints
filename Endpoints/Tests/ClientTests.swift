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
        
        let t = tester.expectError(request) { error in
            let error = error as! URLError
            XCTAssertEqual(error.code, URLError.timedOut)
        }
        
        XCTAssertNotNil(t.urlSessionDataTask)
        XCTAssertNil(t.httpResponse)
        XCTAssertNil(t.statusCode)
    }
    
    func testStatusError() {
        let request = DynamicRequest<Data>(.get, "status/400")
        
        tester.expectError(request) { error in
            if let error = error as? StatusCodeError {
                switch error {
                case .unacceptable(400, _):
                    print("code is ok")
                default:
                    XCTFail("wrong error: \(error)")
                }
            } else {
                XCTFail("wrong error: \(error)")
            }
        }
    }

    func testGetData() {
        let request = DynamicRequest<Data>(.get, "get")
        
        tester.expectSuccess(request) { value in
            XCTAssertFalse(value.isEmpty)
        }
    }

    func testGetString() {
        let request = DynamicRequest<String>(.get, "get", query: [ "inputParam" : "inputParamValue" ])

        tester.expectSuccess(request) { value in
            XCTAssertTrue(value.contains("inputParamValue"))
        }
    }

    func testGetJSONDictionary() {
        let request = DynamicRequest<[String: Any]>(.get, "get", query: [ "inputParam" : "inputParamValue" ])
        
        tester.expectSuccess(request) { jsonDict in
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

    func testParseJSONArray() {
        let inputArray = [ "one", "two", "three" ]
        let arrayData = try! JSONSerialization.data(withJSONObject: inputArray, options: .prettyPrinted)

        let parsedObject = try! DynamicRequest<[String]>.ResponseType.parse(responseData: arrayData, encoding: .utf8)
        
        XCTAssertEqual(inputArray, parsedObject)
    }

    func testFailJSONParsing() {
        let request = DynamicRequest<[String: Any]>(.get, "xml")
        
        tester.expectError(request) { error in
            if let error = error as? CocoaError {
                XCTAssertTrue(error.isPropertyListError)
                XCTAssertEqual(error.code, CocoaError.Code.propertyListReadCorrupt)
            } else {
                XCTFail("wrong error: \(error)")
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
        
        tester.expectSuccess(GetOutput(value: value)) { jsonDict in
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
        
        tester.expectSuccess(req) { value in
            if let headers = value["headers"] as? [String: String] {
                XCTAssertEqual(headers["Accept"], mime)
            } else {
                XCTFail("no headers")
            }
        }
    }

    struct ValidatedRequest: Request {
        typealias ResponseType = [String: Any]
        
        var method: HTTPMethod { return .get }
        var path: String? { return "response-headers" }
        var query: Parameters? { return [ "Mime": mime ] }
        
        var mime: String
        
        func validate(result: URLSessionTaskResult) throws {
            throw StatusCodeError.unacceptable(code: 0, reason: nil)
        }
    }
    
    func testValidatedRequest() {
        let mime = "application/json"
        let req = ValidatedRequest(mime: mime)
        
        let t = tester.expectError(req) { error in }
        XCTAssertEqual(t.httpResponse?.allHeaderFields["Mime"] as? String, mime)
    }
}
