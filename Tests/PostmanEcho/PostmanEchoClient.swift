//
//  PostmanEchoClient.swift
//  
//
//  Created by Alexander Kauer on 06.04.23.
//

import Foundation
@testable import Endpoints

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
