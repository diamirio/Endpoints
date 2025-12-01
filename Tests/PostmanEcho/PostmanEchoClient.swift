// Copyright © 2023 DIAMIR. All Rights Reserved.

@testable import Endpoints
import Foundation

public struct PostmanEchoClient {
    public init() {}

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
