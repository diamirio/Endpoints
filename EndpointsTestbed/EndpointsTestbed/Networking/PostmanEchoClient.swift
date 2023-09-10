//
//  BaseApiClient.swift
//  EndpointsTestbed
//
//  Created by Alexander Kauer on 09.04.23.
//

import Foundation
import Endpoints

public class PostmanEchoClient: AnyAsyncClient {
    
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

