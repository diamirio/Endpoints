// Copyright © 2023 DIAMIR. All Rights Reserved.

@testable import Endpoints
import Foundation

public class PostmanEchoClient: AnyClient {
	public init() {
		let url = URL(string: "https://postman-echo.com")!
		super.init(baseURL: url)
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
