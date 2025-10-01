// Copyright © 2023 DIAMIR. All Rights Reserved.

@testable import Endpoints
import Foundation

public struct PostmanEchoClient: Client {
    public var client: Client
    
    public init() {
        let url = URL(string: "https://postman-echo.com")!
        client = AnyClient(baseURL: url)
    }

    struct MyCall: Call {
        typealias Parser = JSONParser<PostmanEcho>

        var request: URLRequestEncodable {
            Request(.get, "/")
        }
    }
}

struct PostmanEcho: Decodable {
    var url: String
}
