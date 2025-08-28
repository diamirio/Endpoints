@testable import Endpoints
import Foundation
import Testing

@Suite("Client Tests")
struct ClientTests {
    let tester: ClientTester<AnyClient>

    init() {
        let baseURL = URL(string: "https://nghttp2.org/httpbin/")!
        self.tester = ClientTester(client: AnyClient(baseURL: baseURL))
    }

    @Test func testStatusError() async throws {
        do {
            let call = AnyCall<DataResponseParser>(Request(.get, "status/400"))
            _ = try await tester.performTest(call: call)
            #expect(Bool(false), "Should have thrown an exception")
        } catch let endpointsError as EndpointsError {
            #expect(endpointsError.error.localizedDescription == "bad request")
        } catch {
            #expect(Bool(false), "Caught an unexpected error: \(error.localizedDescription)")
        }
    }

    @Test func testGetData() async throws {
        let call = AnyCall<DataResponseParser>(Request(.get, "get"))
        let (_, response) = try await tester.performTest(call: call)
        #expect(response.statusCode == 200)
    }

    @MainActor
    @Test func testGetDataWithCancellation() async throws {
        let task = Task {
            do {
                let call = AnyCall<DataResponseParser>(Request(.get, "delay/5"))
                _ = try await self.tester.performTest(call: call)
                #expect(Bool(false), "Task should have been cancelled before completion.")
            } catch let error as URLError {
                #expect(error.code == .cancelled)
            } catch {
                #expect(Bool(false), "Caught an unexpected error: \(error.localizedDescription)")
            }
        }

        try await Task.sleep(nanoseconds: 100_000_000)

        task.cancel()
        _ = await task.value
    }

    @MainActor
    @Test func testGetDataWithCancellationWhenTaskIsNotStarted() async throws {
        let task = Task {
            do {
                let call = AnyCall<DataResponseParser>(Request(.get, "delay/5"))
                _ = try await self.tester.performTest(call: call)
                #expect(Bool(false), "Task should have been cancelled before completion.")
            } catch let error as URLError {
                #expect(error.code == .cancelled)
            } catch {
                #expect(error is CancellationError)
            }
        }

        task.cancel()
        _ = await task.value
    }

    @Test func testPostRawString() async throws {
        let requestBody = "body"
        let call = AnyCall<DictionaryParser<String, Any>>(Request(
            .post,
            "post",
            header: ["Content-Type": "raw"],
            body: requestBody
        ))
        let (body, _) = try await tester.performTest(call: call)

        let headers = try #require(body["headers"] as? [String: String])
        #expect(headers["Content-Type"] == "raw")
    }

    @Test func testPostString() async throws {
        let requestBody = "key=value"
        let call = AnyCall<DictionaryParser<String, Any>>(Request(.post, "post", body: requestBody))
        let (body, _) = try await tester.performTest(call: call)

        let form = try #require(body["form"] as? [String: String])
        #expect(form["key"] == "value")
    }

    @Test func testPostFormEncodedBody() async throws {
        let params = ["key": "&=?value+*-:_.😀"]
        let requestBody = FormEncodedBody(parameters: params)
        let call = AnyCall<DictionaryParser<String, Any>>(Request(.post, "post", body: requestBody))
        let (body, _) = try await tester.performTest(call: call)

        let form = try #require(body["form"] as? [String: String])
        #expect(form == params)

        let headers = try #require(body["headers"] as? [String: String])
        #expect(headers["Content-Type"] == "application/x-www-form-urlencoded")
    }

    @Test func testPostJSONBody() async throws {
        let params = ["key": "value"]
        let body = try JSONEncodedBody(jsonObject: params)
        let json = try await _testPostJSONBody(body: body)
        #expect(json == params)
    }

    @Test func testPostJSONBodyEncodable() async throws {
        let params = ["key": "value"]
        let json = try await _testPostJSONBody(body: JSONEncodedBody(encodable: params))
        #expect(json == params)
    }

    private func _testPostJSONBody(body: JSONEncodedBody) async throws -> [String: String] {
        let c = AnyCall<DictionaryParser<String, Any>>(Request(.post, "post", body: body))
        let (body, _) = try await tester.performTest(call: c)

        let headers = try #require(body["headers"] as? [String: String], "Headers are not castable")
        #expect(headers["Content-Type"] == "application/json")

        let json = try #require(body["json"] as? [String: String], "JSON body is not castable")

        return json
    }

    @Test func testGetString() async throws {
        let c = AnyCall<StringParser>(Request(.get, "get", query: ["inputParam": "inputParamValue"]))
        let (body, response) = try await tester.performTest(call: c)
        #expect(response.statusCode == 200)
        #expect(body.contains("inputParamValue"))
    }

    @Test func testGetJSONDictionary() async throws {
        let c = AnyCall<DictionaryParser<String, Any>>(Request(.get, "get", query: ["inputParam": "inputParamValue"]))
        let (body, _) = try await tester.performTest(call: c)

        let args = try #require(body["args"])
        let dictArgs = try #require(args as? [String: String])
        let param = try #require(dictArgs["inputParam"])

        #expect(param == "inputParamValue")
    }

    @Test func testParseJSONArray() throws {
        let inputArray = ["one", "two", "three"]
        let arrayData = try JSONSerialization.data(withJSONObject: inputArray)
        
        let parsedObject = try AnyCall<JSONParser<[String]>>.Parser().parse(data: arrayData, encoding: .utf8)
        
        #expect(inputArray == parsedObject)
    }

    @Test func testFailStringParsing() throws {
        let input = "😜 test"
        let data = try #require(input.data(using: .utf8))

        #expect(throws: EndpointsParsingError.self) {
            _ = try StringParser().parse(data: data, encoding: .japaneseEUC)
        }
    }

    @Test func testFailJSONParsing() async throws {
        let c = AnyCall<DictionaryParser<String, Any>>(Request(.get, "xml"))
        
        let error = await #expect(throws: EndpointsError.self) {
            _ = try await tester.performTest(call: c)
        }
        
        if let cocoaError = error?.error as? CocoaError {
            #expect(cocoaError.isPropertyListError)
            #expect(cocoaError.code == CocoaError.Code.propertyListReadCorrupt)
        } else {
            #expect(Bool(false), "Wrong error type thrown")
        }
    }

    @Test func testTypedRequest() async throws {
        let value = "value"
        let c = GetOutput(value: value)
        let (body, _) = try await tester.performTest(call: c)

        let args = try #require(body["args"] as? [String: String], "Response body is not a dictionary")
        let param = try #require(args["param"])
        
        #expect(param == value)
    }

    @Test func testBasicAuth() async throws {
        let auth = BasicAuthorization(user: "a", password: "a")
        let c = AnyCall<DataResponseParser>(Request(.get, "basic-auth/a/a", header: auth.header))
        let (_, response) = try await tester.performTest(call: c)
        #expect(response.statusCode == 200)
    }

    @Test func testBasicAuthFail() async throws {
        let auth = BasicAuthorization(user: "a", password: "b")
        let c = AnyCall<DataResponseParser>(Request(.get, "basic-auth/a/a", header: auth.header))
        
        let error = await #expect(throws: EndpointsError.self) {
            _ = try await tester.performTest(call: c)
        }
        
        let response = try #require(error?.response)
        #expect(response.statusCode == 401)
    }

    @Test func testSimpleAbsoluteURLCall() async throws {
        let url = try #require(URL(string: "https://httpbin.org/get?q=a"))
        let c = AnyCall<DataResponseParser>(url)
        let (_, response) = try await tester.performTest(call: c)
        #expect(response.url == url)
    }

    @Test func testSimpleRelativeURLRequestCall() async throws {
        let url = try #require(URL(string: "get?q=a"))
        let c = AnyCall<DataResponseParser>(URLRequest(url: url))
        let (_, response) = try await tester.performTest(call: c)
        #expect(response.url == URL(string: url.relativeString, relativeTo: self.tester.session.client.baseURL)?.absoluteURL)
    }

    @Test func testRedirect() async throws {
        let req = Request(.get, "relative-redirect/2", header: ["x": "y"])
        let c = AnyCall<DataResponseParser>(req)
        let (_, response) = try await tester.performTest(call: c)
        #expect(response.url == URL(string: "get", relativeTo: self.tester.session.client.baseURL)?.absoluteURL)
    }

    @Test func testNoResponseBody() async throws {
        let c = AnyCall<DataResponseParser>(Request(.get, "status/200"))
        let (_, response) = try await tester.performTest(call: c)
        #expect(response.statusCode == 200)
    }

    // Helper types
    struct TestError: LocalizedError {
        let error: Error?
        let response: HTTPURLResponse? = nil
        let errorDescription: String?

        init(errorDescription: String? = nil, error: Error? = nil) {
            self.errorDescription = errorDescription
            self.error = error
        }
    }

    struct GetOutput: Call {
        typealias Parser = DictionaryParser<String, Any>

        let value: String

        var request: URLRequestEncodable {
            Request(.get, "get", query: ["param": value])
        }
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
}
