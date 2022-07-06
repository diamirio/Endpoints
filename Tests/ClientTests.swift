import XCTest
@testable import Endpoints

class ClientTests: XCTestCase {
    var tester: ClientTester<AnyClient>!
    
    // 2021-02-12: redirect endpoints for httpbin.org no longer work, https://github.com/postmanlabs/httpbin/issues/617
    let baseURL = URL(string: "https://nghttp2.org/httpbin/")!
    override func setUp() {
        tester = ClientTester(test: self, client: AnyClient(baseURL: baseURL))
    }

    func testCancellation() {
        let c = AnyCall<NoContentParser>(Request(.get, "get"))
        
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
        var urlReq = Request(.get, "delay/1").urlRequest
        urlReq.timeoutInterval = 0.5
        
        let c = AnyCall<NoContentParser>(urlReq)
        
        tester.test(call: c) { result in
            self.tester.assert(result: result, isSuccess: false)
            XCTAssertNil(result.response?.statusCode)

            XCTAssertEqual(URLError.timedOut, result.urlError?.code)

            let error = result.error as! URLError
            XCTAssertEqual(error.code, URLError.timedOut)
        }
    }
    
    func testStatusError() {
        let c = AnyCall<DataResponseParser>(Request(.get, "status/400"))
        
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
                XCTFail("wrong error: \(String(describing: result.error))")
            }
        }
    }
    
#if compiler(>=5.5) && canImport(_Concurrency)
    
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0,  *)
    func testStatusErrorAsync() async {
        do {
            let c = AnyCall<DataResponseParser>(Request(.get, "status/400"))
            _ = try await tester.testAsync(call: c)
            XCTFail("Should throw exception")
        } catch {
            XCTAssertEqual(error.localizedDescription, "bad request")
        }
    }
    
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0,  *)
    func testGetDataAsync() async throws {
        let c = AnyCall<DataResponseParser>(Request(.get, "get"))
        let result = try await tester.testAsync(call: c)
        tester.assert(result: result, isSuccess: true, status: 200)
    }
    
#endif
    
    func testGetData() {
        let c = AnyCall<DataResponseParser>(Request(.get, "get"))

        tester.test(call: c) { result in
            self.tester.assert(result: result, isSuccess: true, status: 200)
        }
    }

    func testGetDataNoContentParser() {
        let c = AnyCall<NoContentParser>(Request(.get, "get"))

        tester.test(call: c) { result in
            self.tester.assert(result: result, isSuccess: true, status: 200)
        }
    }
    
    func testPostRawString() {
        let body = "body"
        let c = AnyCall<DictionaryParser<String, Any>>(Request(.post, "post", header: [ "Content-Type": "raw" ], body: body))
        
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
        let c = AnyCall<DictionaryParser<String, Any>>(Request(.post, "post", body: body))
        
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
        let params = [ "key": "&=?value+*-:_.😀" ]
        let body = FormEncodedBody(parameters: params)
        let c = AnyCall<DictionaryParser<String, Any>>(Request(.post, "post", body: body))
        
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
    
    func testPostJSONBody() throws {
        let params = ["key": "value"]
        let body = try JSONEncodedBody(jsonObject: params)
        _testPostJSONBody(body: body, validateJSON: { json in
            XCTAssertEqual(json, params)
        })
    }

    func testPostJSONBodyEncodable() throws {
        let params = ["key": "value"]
        _testPostJSONBody(body: try JSONEncodedBody(encodable: params), validateJSON: { json in
            XCTAssertEqual(json, params)
        })
    }

    func _testPostJSONBody(body: JSONEncodedBody, validateJSON: @escaping (([String: String]) -> Void)) {
        let c = AnyCall<DictionaryParser<String, Any>>(Request(.post, "post", body: body))

        tester.test(call: c) { result in
            self.tester.assert(result: result, isSuccess: true, status: 200)

            result.onSuccess { value in
                if let json = value["json"] as? [String: String] {
                    validateJSON(json)
                } else {
                    XCTFail("json not found")
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
        let c = AnyCall<StringParser>(Request(.get, "get", query: [ "inputParam" : "inputParamValue" ]))
        
        tester.test(call: c) { result in
            self.tester.assert(result: result, isSuccess: true, status: 200)
            
            if let string = result.value {
                XCTAssertTrue(string.contains("inputParamValue"))
            }
        }
    }
    
    func testGetJSONDictionary() {
        let c = AnyCall<DictionaryParser<String, Any>>(Request(.get, "get", query: [ "inputParam" : "inputParamValue" ]))
        
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

        let parsedObject = try! AnyCall<JSONParser<[String]>>.Parser().parse(data: arrayData, encoding: .utf8)
        
        XCTAssertEqual(inputArray, parsedObject)
    }
    
    func testFailStringParsing() {
        let input = "😜 test"
        let data = input.data(using: .utf8)!
        
        do {
            let parsed = try StringParser().parse(data: data, encoding: .japaneseEUC)
            XCTAssertEqual(parsed, input)
            XCTFail("this should actually fail")
        } catch {
            XCTAssertTrue(error is ParsingError)
            XCTAssertTrue(error.localizedDescription.hasPrefix("String could not be parsed with encoding"))
        }
    }
    
    func testFailJSONParsing() {
        let c = AnyCall<DictionaryParser<String, Any>>(Request(.get, "xml"))
        
        tester.test(call: c) { result in
            self.tester.assert(result: result, isSuccess: false, status: 200)
            
            if let error = result.error as? CocoaError {
                XCTAssertTrue(error.isPropertyListError)
                XCTAssertEqual(error.code, CocoaError.Code.propertyListReadCorrupt)
            } else {
                XCTFail("wrong error: \(String(describing: result.error))")
            }
        }
    }
    
    struct GetOutput: Call {
        typealias Parser = DictionaryParser<String, Any>
        
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
    
    struct ValidatingCall: Call {
        typealias Parser = DictionaryParser<String, Any>
        
        var mime: String
        
        var request: URLRequestEncodable {
            return Request(.get, "response-headers", query: [ "Mime": mime ])
        }
        
        func validate(result: URLSessionTaskResult) throws {
            throw StatusCodeError.unacceptable(code: 0, reason: nil)
        }
    }
    
    class ValidatingClient: AnyClient {
        override func validate(result: URLSessionTaskResult) throws {
            throw StatusCodeError.unacceptable(code: 1, reason: nil)
        }
    }
    
    func testClientValidation() {
        // check if call validation comes before client validation
        let client = ValidatingClient(baseURL: self.tester.session.client.baseURL)
        let tester = ClientTester(test: self, client: client)
        
        let c = AnyCall<DataResponseParser>(Request(.get, "get"))
        
        tester.test(call: c) { result in
            self.tester.assert(result: result, isSuccess: false)
            
            guard let error = result.error as? StatusCodeError else {
                XCTFail("error expected")
                return
            }
            
            switch error {
            case .unacceptable(let code, _):
                XCTAssertEqual(code, 1, "client should throw error")
            }
        }
    }
    
    func testValidatingRequest() {
        // check if call validation comes before client validation
        let client = ValidatingClient(baseURL: self.tester.session.client.baseURL)
        let tester = ClientTester(test: self, client: client)
        
        let mime = "application/json"
        let c = ValidatingCall(mime: mime)
        
        tester.test(call: c) { result in
            self.tester.assert(result: result, isSuccess: false)
            
            guard let error = result.error as? StatusCodeError else {
                XCTFail("error expected")
                return
            }
            
            switch error {
            case .unacceptable(let code, _):
                XCTAssertEqual(code, 0, "request should throw error, not client")
            }
            
            let responseMime = result.response?.allHeaderFields["Mime"] ?? result.response?.allHeaderFields["mime"]
            XCTAssertEqual(responseMime as? String, mime)
        }
    }
    
    func testBasicAuth() {
        let auth = BasicAuthorization(user: "a", password: "a")
        let c = AnyCall<DataResponseParser>(Request(.get, "basic-auth/a/a", header: auth.header))
        
        tester.test(call: c) { result in
            self.tester.assert(result: result, isSuccess: true)
        }
    }
    
    func testBasicAuthFail() {
        let auth = BasicAuthorization(user: "a", password: "b")
        let c = AnyCall<DataResponseParser>(Request(.get, "basic-auth/a/a", header: auth.header))
        
        tester.test(call: c) { result in
            self.tester.assert(result: result, isSuccess: false)
        }
    }

    func testSimpleAbsoluteURLCall() {
        let url = URL(string: "https://httpbin.org/get?q=a")!
        let c = AnyCall<DataResponseParser>(url)
        
        tester.test(call: c) { result in
            self.tester.assert(result: result)
            XCTAssertEqual(result.response?.url, url)
        }
    }
    
    func testSimpleRelativeURLRequestCall() {
        let url = URL(string: "get?q=a")!
        let c = AnyCall<DataResponseParser>(URLRequest(url: url))
        
        tester.test(call: c) { result in
            self.tester.assert(result: result)
            XCTAssertEqual(result.response?.url, URL(string: url.relativeString, relativeTo: self.baseURL)?.absoluteURL)
        }
    }
    
    func testRedirect() {
        let req = Request(.get, "relative-redirect/2", header: ["x": "y"])
        let c = AnyCall<DataResponseParser>(req)

        tester.test(call: c) { result in
            self.tester.assert(result: result)
            XCTAssertEqual(result.response?.url, URL(string: "get", relativeTo: self.baseURL)?.absoluteURL)
        }
    }
}
