import Endpoints
import Foundation

struct HTTPBinClient: Client {
    var client: Client

    init() {
        let url = URL(string: "https://httpbin.org/")!
        self.client = AnyClient(baseURL: url)
    }

    struct GetStatusCode: Call {
        let deliveredStatusCode: Int

        typealias Parser = JSONParser<String>

        var request: URLRequestEncodable {
            Request(.get, "/status/\(deliveredStatusCode)")
        }
    }
}
