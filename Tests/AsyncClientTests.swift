// Copyright © 2023 DIAMIR. All Rights Reserved.

@testable import Endpoints
import XCTest

class AsyncClientTests: XCTestCase {
    var tester: AsyncClientTester<AnyClient>!

    // 2021-02-12: redirect endpoints for httpbin.org no longer work, https://github.com/postmanlabs/httpbin/issues/617
    let baseURL = URL(string: "https://nghttp2.org/httpbin/")!
    override func setUp() {
        tester = AsyncClientTester(test: self, client: AnyClient(baseURL: baseURL))
    }

    func testStatusErrorAsync() async throws {
        do {
            let call = AnyCall<DataResponseParser>(Request(.get, "status/400"))
            _ = try await tester.test(call: call)
            XCTFail("Should throw exception")
        }
        catch let endpointsError as EndpointsError {
            XCTAssertEqual(endpointsError.error.localizedDescription, "bad request")
        }
    }

    func testGetDataAsync() async throws {
        let call = AnyCall<DataResponseParser>(Request(.get, "get"))
        let (_, response) = try await tester.test(call: call)
        XCTAssertEqual(response.statusCode, 200)
    }

    func testGetDataAsyncWithCancellation() async throws {
        let exp = expectation(description: "task was executed until end")
        exp.isInverted = true

        let task = Task {
            let call = AnyCall<DataResponseParser>(Request(.get, "get"))
            _ = try await tester.test(call: call)
            exp.fulfill()
        }

        try await Task.sleep(nanoseconds: 400)
        task.cancel()
        await fulfillment(of: [exp], timeout: 5)

        XCTAssertTrue(task.isCancelled, "Parent Task should be cancelled.")
    }

    func testGetDataAsyncWithCancellationWhenTaskIsNotStarted() async throws {
        let exp = expectation(description: "task was executed until end")
        exp.isInverted = true

        let task = Task {
            let call = AnyCall<DataResponseParser>(Request(.get, "get"))
            _ = try await tester.test(call: call)
            exp.fulfill()
        }

        task.cancel()
        await fulfillment(of: [exp], timeout: 5)
        XCTAssertTrue(task.isCancelled, "Parent Task should be cancelled.")
    }

    func testGetData() async throws {
        let call = AnyCall<DataResponseParser>(Request(.get, "get"))
        let (body, response) = try await tester.test(call: call)

        XCTAssert(response.statusCode == 200)
        XCTAssertNotNil(body)
    }

    func testPostRawString() async throws {
        let requestBody = "body"
        let call = AnyCall<DictionaryParser<String, Any>>(Request(
            .post,
            "post",
            header: ["Content-Type": "raw"],
            body: requestBody
        ))
        let (body, _) = try await tester.test(call: call)

        guard let headers = body["headers"] as? [String: String] else {
            XCTFail("headers not found")
            return
        }

        XCTAssertEqual(headers["Content-Type"], "raw")
    }

    func testPostString() async throws {
        // foundation urlrequest defaults to form encoding
        let requestBody = "key=value"
        let call = AnyCall<DictionaryParser<String, Any>>(Request(.post, "post", body: requestBody))
        let (body, _) = try await tester.test(call: call)

        guard let form = body["form"] as? [String: String] else {
            XCTFail("form not found")
            return
        }

        XCTAssertEqual(form["key"], "value")
    }

    func testPostFormEncodedBody() async throws {
        let params = ["key": "&=?value+*-:_.😀"]
        let requestBody = FormEncodedBody(parameters: params)
        let call = AnyCall<DictionaryParser<String, Any>>(Request(.post, "post", body: requestBody))
        let (body, _) = try await tester.test(call: call)

        guard let form = body["form"] as? [String: String] else {
            XCTFail("form not found")
            return
        }
        XCTAssertEqual(form, params)

        guard let headers = body["headers"] as? [String: String] else {
            XCTFail("form not found")
            return
        }
        XCTAssertEqual(headers["Content-Type"], "application/x-www-form-urlencoded")
    }

    func testPostJSONBody() async throws {
        let params = ["key": "value"]
        let body = try JSONEncodedBody(jsonObject: params)
        let json = try await _testPostJSONBody(body: body)
        XCTAssertEqual(json, params)
    }

    func testPostJSONBodyEncodable() async throws {
        let params = ["key": "value"]
        let json = try await _testPostJSONBody(body: JSONEncodedBody(encodable: params))
        XCTAssertEqual(json, params)
    }

    func _testPostJSONBody(body: JSONEncodedBody) async throws -> [String: String] {
        let c = AnyCall<DictionaryParser<String, Any>>(Request(.post, "post", body: body))
        let (body, _) = try await tester.test(call: c)

        guard let headers = body["headers"] as? [String: String] else {
            throw TestError(errorDescription: "Headers are not cast-able")
        }
        XCTAssertEqual(headers["Content-Type"], "application/json")

        guard let json = body["json"] as? [String: String] else {
            throw TestError(errorDescription: "Json body is not cast-able")
        }

        return json
    }

    func testGetString() async throws {
        let c = AnyCall<StringParser>(Request(.get, "get", query: ["inputParam": "inputParamValue"]))
        let (body, response) = try await tester.test(call: c)
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertTrue(body.contains("inputParamValue"))
    }

    func testGetJSONDictionary() async throws {
        let c = AnyCall<DictionaryParser<String, Any>>(Request(.get, "get", query: ["inputParam": "inputParamValue"]))
        let (body, _) = try await tester.test(call: c)

        let args = body["args"]
        XCTAssertNotNil(args)

        guard let args,
              let dictArgs = args as? [String: String],
              let param = dictArgs["inputParam"]
        else {
            XCTFail("Condition not matched")
            return
        }

        XCTAssertEqual(param, "inputParamValue")
    }

    func testParseJSONArray() {
        let inputArray = ["one", "two", "three"]
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
        }
        catch {
            XCTAssertTrue(error is EndpointsParsingError)
            XCTAssertTrue(error.localizedDescription.hasPrefix("String could not be parsed with encoding"))
        }
    }

    func testFailJSONParsing() async throws {
        let c = AnyCall<DictionaryParser<String, Any>>(Request(.get, "xml"))
        do {
            _ = try await tester.test(call: c)
        }
        catch let endpointsError as EndpointsError {
            if let error = endpointsError.error as? CocoaError {
                XCTAssertTrue(error.isPropertyListError)
                XCTAssertEqual(error.code, CocoaError.Code.propertyListReadCorrupt)
            }
            else {
                XCTFail("wrong error: \(String(describing: endpointsError.error))")
            }
        }
    }

    struct GetOutput: Call {
        typealias Parser = DictionaryParser<String, Any>

        let value: String

        var request: URLRequestEncodable {
            Request(.get, "get", query: ["param": value])
        }
    }

    func testTypedRequest() async throws {
        let value = "value"
        let c = GetOutput(value: value)
        let (body, _) = try await tester.test(call: c)

        guard let args = body["args"] as? [String: String] else {
            throw TestError(errorDescription: "Response body is not a dictionary")
        }

        let param = args["param"]
        XCTAssertNotNil(param)
        XCTAssertEqual(param, value)
    }

    struct ValidatingCall: Call {
        typealias Parser = DictionaryParser<String, Any>

        var mime: String

        var request: URLRequestEncodable {
            Request(.get, "response-headers", query: ["Mime": mime])
        }

        func validate(result _: URLSessionTaskResult) throws {
            throw StatusCodeError.unacceptable(code: 0, reason: nil)
        }
    }

    func testBasicAuth() async throws {
        let auth = BasicAuthorization(user: "a", password: "a")
        let c = AnyCall<DataResponseParser>(Request(.get, "basic-auth/a/a", header: auth.header))
        let (_, response) = try await tester.test(call: c)
        XCTAssertEqual(response.statusCode, 200)
    }

    func testBasicAuthFail() async throws {
        let auth = BasicAuthorization(user: "a", password: "b")
        let c = AnyCall<DataResponseParser>(Request(.get, "basic-auth/a/a", header: auth.header))
        do {
            _ = try await tester.test(call: c)
            XCTFail("Should throw error")
        }
        catch let error as EndpointsError {
            XCTAssertNotNil(error.response)
            XCTAssertEqual(error.response?.statusCode, 401)
        }
    }

    func testSimpleAbsoluteURLCall() async throws {
        let url = URL(string: "https://httpbin.org/get?q=a")!
        let c = AnyCall<DataResponseParser>(url)
        let (_, response) = try await tester.test(call: c)
        XCTAssertEqual(response.url, url)
    }

    func testSimpleRelativeURLRequestCall() async throws {
        let url = URL(string: "get?q=a")!
        let c = AnyCall<DataResponseParser>(URLRequest(url: url))
        let (_, response) = try await tester.test(call: c)
        XCTAssertEqual(response.url, URL(string: url.relativeString, relativeTo: baseURL)?.absoluteURL)
    }

    func testRedirect() async throws {
        let req = Request(.get, "relative-redirect/2", header: ["x": "y"])
        let c = AnyCall<DataResponseParser>(req)
        let (_, response) = try await tester.test(call: c)
        XCTAssertEqual(response.url, URL(string: "get", relativeTo: baseURL)?.absoluteURL)
    }

    func testNoResponseBody() async throws {
        let c = AnyCall<DataResponseParser>(Request(.get, "status/200"))
        let (_, response) = try await tester.test(call: c)
        XCTAssertEqual(response.statusCode, 200)
    }
}

struct CustomError: LocalizedError {
    let error: Error
    let response: HTTPURLResponse? = nil

    var errorDescription: String? {
        error.localizedDescription
    }
}
