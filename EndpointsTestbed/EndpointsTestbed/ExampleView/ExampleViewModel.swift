//
//  ExampleViewModel.swift
//  EndpointsTestbed
//
//  Created by Alexander Kauer on 09.04.23.
//

import Foundation
import Endpoints

@MainActor
class ExampleViewModel: ObservableObject {
    @Published var text: String = ""
    
    // can be injected
    private let session: AsyncSession<BaseApiClient>
    
    init() {
        let client = BaseApiClient()
        self.session = AsyncSession(with: client)
    }
    
    func exectueRequest() {
        Task {
            // BaseApiClient.ExampleGetCall() could also be created via enum wrapper instad of directly instantiating it here
            let (body, response) = try await session.start(call: BaseApiClient.ExampleGetCall())
            
            guard response.statusCode == 200 else { return }
            self.text = body.url
        }
    }
}
