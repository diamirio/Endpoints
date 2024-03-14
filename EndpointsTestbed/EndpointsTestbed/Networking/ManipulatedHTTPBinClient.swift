import Endpoints
import Foundation

class ManipulatedHTTPBinClient: AnyClient {
    private var defaultClient: AnyClient

    init() {
        let url = URL(string: "https://httpbin.org/")!
        self.defaultClient = AnyClient(baseURL: url)
        super.init(baseURL: url)
    }

    override func encode(call: some Endpoints.Call) async throws -> URLRequest {
        // Custom manipulation i.e. OAuth implementation
        print("- MANIPULATED encode -")
        return try await defaultClient.encode(call: call)
    }

    override func parse<C>(response: HTTPURLResponse?, data: Data?, for call: C) async throws -> C.Parser.OutputType
        where C: Call {
        // Custom manipulation i.e. react on error responses or invalid tokens
        print("- MANIPULATED parse -")
        return try await defaultClient.parse(response: response, data: data, for: call)
    }

    override func validate(response: HTTPURLResponse?, data: Data?) async throws {
        // Custom validation if needed
        print("- MANIPULATED validate -")
    }

    struct GetStatusCode: Call {
        typealias Parser = JSONParser<String>

        let deliveredStatusCode: Int

        var request: URLRequestEncodable {
            Request(.get, "/status/\(deliveredStatusCode)")
        }
    }
}
