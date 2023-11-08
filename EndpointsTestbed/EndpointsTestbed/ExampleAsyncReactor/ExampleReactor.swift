//
//  ExampleReactor.swift
//  EndpointsTestbed
//
//  Created by Alexander Kauer on 08.11.23.
//

import AsyncReactor
import Foundation
import Endpoints

class ExampleReactor: AsyncReactor {
    
    enum Action {
        case executeRequests
    }
    
    struct State {
        var text = ""
    }
    
    @Published private(set) var state = State()
    
    func action(_ action: Action) async {
        switch action {
        case .executeRequests:
            await executeRequest()
        }
    }
    
    private func executeRequest() async {
        do {
            let (body, response) = try await world.postmanSession.start(
                call: PostmanEchoClient.ExampleGetCall()
            )
            
            guard response.statusCode == 200 else { return }
            
            await MainActor.run {
                state.text = body.url
            }
        } catch {
            guard let error = error as? EndpointsError else { return }
            print(error.response?.statusCode ?? "")
        }
    }
}
