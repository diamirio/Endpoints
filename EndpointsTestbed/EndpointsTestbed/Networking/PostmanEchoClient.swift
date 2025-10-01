import Endpoints
import Foundation

struct PostmanEchoClient: Client {
    let client: Client

    init() {
        let baseURL = URL(string: "https://postman-echo.com")!
        self.client = AnyClient(baseURL: baseURL)
    }

    struct ExampleGetCall: Call {
        typealias Parser = JSONParser<ExampleModel>

        var request: URLRequestEncodable {
            Request(.get, "/get")
        }
    }
}
