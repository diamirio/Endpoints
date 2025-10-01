import Endpoints
import Foundation

struct ManipulatedHTTPBinClient: Client {
    var client: Client

    init() {
        let url = URL(string: "https://httpbin.org/")!
        self.client = AnyClient(baseURL: url)
    }

    func encode(call: some Endpoints.Call) async throws -> URLRequest {
        // Custom manipulation i.e. OAuth implementation
        print("- MANIPULATED encode -")
        return try await client.encode(call: call)
    }

    func parse<C>(response: HTTPURLResponse?, data: Data?, for call: C) async throws -> C.Parser.OutputType
        where C: Call {
        // Custom manipulation i.e. react on error responses or invalid tokens
        print("- MANIPULATED parse -")
        return try await client.parse(response: response, data: data, for: call)
    }

    func validate(response: HTTPURLResponse?, data: Data?) async throws {
        // Custom validation if needed
        print("- MANIPULATED validate -")
        return try await client.validate(response: response, data: data)
    }

    struct GetStatusCode: Call {
        typealias Parser = JSONParser<String>

        let deliveredStatusCode: Int

        var request: URLRequestEncodable {
            Request(.get, "/status/\(deliveredStatusCode)")
        }
    }
}
