import XCTest
@testable import Endpoints

class ClientTests: XCTestCase {
    var tester: ClientTester<BaseClient>!
    
    override func setUp() {
        tester = ClientTester(test: self, client: BaseClient(baseURL: URL(string: "http://httpbin.org")!))
    }
    
    func testCancellation() {
        let c = DynamicCall<Data>(Request(.get, "get"))
        
        let exp = expectation(description: "")
        let task = tester.session.start(call: c) { result in
            XCTAssertTrue(result.wasCancelled)
            XCTAssertNotNil(result.error)
            XCTAssertNotNil(result.urlError)
            
            result.onError { error in
                XCTFail("was cancelled. this is not considered an error. should not be called.")
            }.onSuccess { value in
                XCTFail("was cancelled. should not be called.")
            }
            exp.fulfill()
        }
        
        task.cancel()
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testTimeoutError() {
        let c = DynamicCall<Data>(Request(.get, "delay/1"), encode: { $0.timeoutInterval = 0.5 })
        
        tester.test(call: c) { result in
            self.tester.assert(result: result, isSuccess: false)
            XCTAssertNil(result.response?.statusCode)
            
            XCTAssertEqual(result.error?.localizedDescription, "The request timed out.")

            let error = result.error as! URLError
            XCTAssertEqual(error.code, URLError.timedOut)
        }
    }
    
    func testStatusError() {
        let c = DynamicCall<Data>(Request(.get, "status/400"))
        
        tester.test(call: c) { result in
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
        let c = DynamicCall<Data>(Request(.get, "get"))
        
        tester.test(call: c) { result in
            self.tester.assert(result: result, isSuccess: true, status: 200)
        }
    }
    
    func testPostRawString() {
        let body = "body"
        let c = DynamicCall<[String: Any]>(Request(.post, "post", header: [ "Content-Type": "raw" ], body: body))
        
        tester.test(call: c) { result in
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
        let c = DynamicCall<[String: Any]>(Request(.post, "post", body: body))
        
        tester.test(call: c) { result in
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
        let c = DynamicCall<[String: Any]>(Request(.post, "post", body: body))
        
        tester.test(call: c) { result in
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
        let c = DynamicCall<[String: Any]>(Request(.post, "post", body: body))
        
        tester.test(call: c) { result in
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
        let c = DynamicCall<String>(Request(.get, "get", query: [ "inputParam" : "inputParamValue" ]))
        
        tester.test(call: c) { result in
            self.tester.assert(result: result, isSuccess: true, status: 200)
            
            if let string = result.value {
                XCTAssertTrue(string.contains("inputParamValue"))
            }
        }
    }
    
    func testGetJSONDictionary() {
        let c = DynamicCall<[String: Any]>(Request(.get, "get", query: [ "inputParam" : "inputParamValue" ]))
        
        tester.test(call: c) { result in
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

        let parsedObject = try! DynamicCall<[String]>.ResponseType.parse(data: arrayData, encoding: .utf8)
        
        XCTAssertEqual(inputArray, parsedObject)
    }
    
    func testFailStringParsing() {
        let input = "😜 test"
        let data = input.data(using: .utf8)!
        
        do {
            let parsed = try String.parse(data: data, encoding: .japaneseEUC)
            XCTAssertEqual(parsed, input)
            XCTFail("this should actually fail")
        } catch {
            XCTAssertTrue(error is ParsingError)
            XCTAssertEqual(error.localizedDescription, "String could not be parsed with encoding 3")
        }
    }
    
    func testFailJSONParsing() {
        let c = DynamicCall<[String: Any]>(Request(.get, "xml"))
        
        tester.test(call: c) { result in
            self.tester.assert(result: result, isSuccess: false, status: 200)
            
            if let error = result.error as? CocoaError {
                XCTAssertTrue(error.isPropertyListError)
                XCTAssertEqual(error.code, CocoaError.Code.propertyListReadCorrupt)
            } else {
                XCTFail("wrong error: \(result.error)")
            }
        }
    }
    
    struct GetOutput: Call {
        typealias ResponseType = [String: Any]
        
        let value: String
        
        var request: URLRequestEncodable {
            return Request(.get, "get", query: ["param" : value])
        }
    }
    
    func testTypedRequest() {
        let value = "value"
        
        tester.test(call: GetOutput(value: value)) { result in
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
    
    struct ValidatedRequest: Call {
        typealias ResponseType = [String: Any]
        
        var mime: String
        
        var request: URLRequestEncodable {
            return Request(.get, "response-headers", query: [ "Mime": mime ])
        }
        
        func validate(result: URLSessionTaskResult) throws {
            throw StatusCodeError.unacceptable(code: 0, reason: nil)
        }
    }
    
    func testValidatedRequest() {
        let mime = "application/json"
        let c = ValidatedRequest(mime: mime)
        
        tester.test(call: c) { result in
            self.tester.assert(result: result, isSuccess: false)
            
            XCTAssertEqual(result.response?.allHeaderFields["Mime"] as? String, mime)
        }
    }
    
    func testBasicAuth() {
        let auth = BasicAuthorization(user: "a", password: "a")
        let c = DynamicCall<Data>(Request(.get, "basic-auth/a/a", header: auth.header))
        
        tester.test(call: c) { result in
            self.tester.assert(result: result, isSuccess: true)
        }
    }
    
    func testBasicAuthFail() {
        let auth = BasicAuthorization(user: "a", password: "b")
        let c = DynamicCall<Data>(Request(.get, "basic-auth/a/a", header: auth.header))
        
        tester.test(call: c) { result in
            self.tester.assert(result: result, isSuccess: false)
        }
    }

    func testSimpleURLCall() {
        let c = DynamicCall<Data>(URL(string: "https://httpbin.org/get?q=a")!)
        
        tester.test(call: c) { result in
            self.tester.assert(result: result)
        }
    }
    
    func testSimpleURLRequestCall() {
        let c = DynamicCall<Data>(URLRequest(url: URL(string: "https://httpbin.org/get?q=a")!))
        
        tester.test(call: c) { result in
            self.tester.assert(result: result)
        }
    }
}
