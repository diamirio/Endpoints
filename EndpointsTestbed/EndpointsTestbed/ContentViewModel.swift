//
//  ContentViewModel.swift
//  EndpointsTestbed
//
//  Created by Alexander Kauer on 06.04.23.
//

import Foundation
import Endpoints

@MainActor
class ContentViewModel: ObservableObject {
    
    func someCall() {
        Task {
            let url = URL(string: "https://postman-echo.com")!
            let myClient = AnyAsyncClient(baseURL: url)
            let mySession = AsyncSession(with: myClient)
            
            let (body, urlResponse) = try await mySession.start(call: BaseApiClient.ExampleGetCall())
            
            // do whatever you like to do with the response
        }
    }
}
