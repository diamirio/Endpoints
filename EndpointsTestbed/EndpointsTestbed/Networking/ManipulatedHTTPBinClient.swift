import Endpoints
import Foundation

class ManipulatedHTTPBinClient: AsyncClient {
	private var defaultClient: AnyAsyncClient

	init() {
		let url = URL(string: "https://httpbin.org/")!
		self.defaultClient = AnyAsyncClient(baseURL: url)
	}

	func encode(call: some Endpoints.Call) async throws -> URLRequest {
		// Custom manipulation i.e. OAuth implementation
		print("- MANIPULATED encode -")
		return try await defaultClient.encode(call: call)
	}

	func parse<C>(sessionTaskResult result: Endpoints.URLSessionTaskResult, for call: C) async throws -> C.Parser
		.OutputType where C: Endpoints.Call {
		// Custom manipulation i.e. react on error responses or invalid tokens
		print("- MANIPULATED parse -")
		return try await defaultClient.parse(sessionTaskResult: result, for: call)
	}

	struct GetStatusCode: Call {
		let deliveredStatusCode: Int

		typealias Parser = JSONParser<String>

		var request: URLRequestEncodable {
			Request(.get, "/status/\(deliveredStatusCode)")
		}
	}
}
