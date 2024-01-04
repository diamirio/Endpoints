// Copyright © 2023 DIAMIR. All Rights Reserved.

@testable import Endpoints
import XCTest

class RequestTests: XCTestCase {
	func testRelativeRequestEncoding() async throws {
		let base = "https://httpbin.org/"
		let queryParams = ["q": "Äin €uro", "a": "test"]

		func validate(request: URLRequest) {
			if let url = request.url, let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
				XCTAssertEqual("https", components.scheme)
				XCTAssertEqual("httpbin.org", components.host)
				XCTAssertEqual("/get", components.path)

				let queryItems = components.queryItems?.sorted(by: { $0.name < $1.name })
				XCTAssertEqual(URLQueryItem(name: "a", value: "test"), queryItems?[0])
				XCTAssertEqual(URLQueryItem(name: "q", value: "Äin €uro"), queryItems?[1])

				// test encoding
				XCTAssertTrue(url.absoluteString.contains("%C3%84in%20%E2%82%ACuro"))
			}
			else {
				XCTFail("Creating URLComponents from \(String(describing: request.url)) failed")
			}
		}

		let request1 = try await testRequestEncoding(baseUrl: base, path: "get", queryParams: queryParams)
		validate(request: request1)

		let request2 = try await testRequestEncoding(baseUrl: base + "get", queryParams: queryParams)
		validate(request: request2)
	}

	func testHATEOASRequest() async throws {
		let absoluteURL = URL(string: "https://httpbin.org/get?x=z")!
		let body = try! JSONEncodedBody(jsonObject: ["x": "y"])

		var req = Request(.get, "post", query: ["x": "y"], header: ["x": "y"], body: body)
		req.url = absoluteURL
		let c = AnyCall<DataResponseParser>(req)

		let urlReq = try await AnyClient(baseURL: URL(string: "http://google.com")!).encode(call: c)

		XCTAssertEqual(urlReq.url, absoluteURL)
		XCTAssertEqual(urlReq.httpBody, body.requestData)
		XCTAssertEqual(urlReq.allHTTPHeaderFields?["Content-Type"], "application/json")
		XCTAssertEqual(urlReq.allHTTPHeaderFields?["x"], "y")
	}

	func testEmptyCurlRepresentation() {
		let r = Request(
			.get,
			url: URL(string: "https://httpbin.org/get?x=z")!,
			header: ["a": "b"],
			body: "BODY".data(using: .utf8)
		)
		let curl = r.cURLRepresentation(prettyPrinted: false)

		print(curl)
		print(r.cURLRepresentation(prettyPrinted: true))

		XCTAssertEqual(curl, "$ curl -i -X GET -H \"a: b\" -d \"BODY\" \"https://httpbin.org/get?x=z\"")
	}

	func testEmptyBodyCurlRepresentation() {
		let r = Request(.get, url: URL(string: "https://httpbin.org/get?x=z")!, header: ["a": "b"])
		let curl = r.cURLRepresentation(prettyPrinted: false)

		print(curl)
		print(r.cURLRepresentation(prettyPrinted: true))

		XCTAssertEqual(
			curl,
			"$ curl -i -X GET -H \"a: b\" -d \"\" \"https://httpbin.org/get?x=z\"",
			"-d should always be added for correct Content-Length header"
		)
	}

	func testBinaryDataCurlRepresentation() throws {
		let body = try FileUtil.load(named: "binary", withExtension: "jpg")
		let r = Request(.get, url: URL(string: "https://httpbin.org/get?x=z")!, header: ["a": "b"], body: body)
		let curl = r.cURLRepresentation(prettyPrinted: false, bodyEncoding: .utf8)

		print(curl)
		print(r.cURLRepresentation(prettyPrinted: true))

		XCTAssertEqual(
			curl,
			"$ curl -i -X GET -H \"a: b\" -d \"<binary data (420 bytes) not convertible to Unicode (UTF-8)>\" \"https://httpbin.org/get?x=z\"",
			"binary data"
		)
	}
}

extension RequestTests {
	func testRequestEncoding(
		baseUrl: String,
		path: String? = nil,
		queryParams: [String: String]? = nil
	) async throws -> URLRequest {
		let request = Request(.get, path, query: queryParams)
		let call = AnyCall<DataResponseParser>(request)
		let client = AnyClient(baseURL: URL(string: baseUrl)!)
		let urlRequest = try await client.encode(call: call)

		let (data, response) = try await URLSession.shared.data(for: urlRequest)

		let httpResponse = response as! HTTPURLResponse
		XCTAssertNotNil(data)
		XCTAssertEqual(httpResponse.statusCode, 200)

		return urlRequest
	}
}
