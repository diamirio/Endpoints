import Endpoints
import Foundation

class HTTPBinClient: AnyAsyncClient {
    public init() {
        let url = URL(string: "https://httpbin.org/")!
        super.init(baseURL: url)
    }

    struct GetStatusCode: Call {
        let deliveredStatusCode: Int

        typealias Parser = JSONParser<String>

        var request: URLRequestEncodable {
            Request(.get, "/status/\(deliveredStatusCode)")
        }
    }
}
