//
//  BaseApiClient.swift
//  EndpointsTestbed
//
//  Created by Alexander Kauer on 09.04.23.
//

import Foundation
import Endpoints

public class BaseApiClient: AnyAsyncClient {
    
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

// manipulation example
class MyClient: AsyncClient {
    typealias RawValue = String.Type
    

    var anyClient: AnyAsyncClient
    
    init(url: URL) {
        anyClient = AnyAsyncClient(baseURL: url)
    }
    
    func encode<C>(call: C) async throws -> URLRequest where C : Endpoints.Call {
        
        // Custom manipulation i.e. OAuth implementation
        
        return try await anyClient.encode(call: call)
    }
    
    func parse<C>(sessionTaskResult result: Endpoints.URLSessionTaskResult, for call: C) async throws -> C.Parser.OutputType where C : Endpoints.Call {
        
        // Custom manipulation i.e. react on error responses
        
        return try await anyClient.parse(sessionTaskResult: result, for: call)
    }
}
