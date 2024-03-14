import Endpoints
import Foundation

public class PostmanEchoClient: AnyClient {
    public init() {
        let url = URL(string: "https://postman-echo.com")!
        super.init(baseURL: url)
    }

    struct ExampleGetCall: Call {
        typealias Parser = JSONParser<ExampleModel>

        var request: URLRequestEncodable {
            Request(.get, "/get")
        }
    }
}
