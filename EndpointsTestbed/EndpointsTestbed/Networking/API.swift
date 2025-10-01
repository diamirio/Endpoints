//
//  API.swift
//  EndpointsTestbed
//
//  Created by Alexander Kauer on 11.09.25.
//

import Endpoints
import Foundation

actor API {
    var postmanSession: Session<PostmanEchoClient>
    var httpBinSession: Session<HTTPBinClient>
    var manipulatedHttpBinSession: Session<ManipulatedHTTPBinClient>

    init() {
        let postmanClient = PostmanEchoClient()
        self.postmanSession = Session(with: postmanClient)

        let httpBinClient = HTTPBinClient()
        self.httpBinSession = Session(with: httpBinClient)

        let manipulatedHttpBinClient = ManipulatedHTTPBinClient()
        self.manipulatedHttpBinSession = Session(with: manipulatedHttpBinClient)
    }

    func loadData() async throws -> (ExampleModel, HTTPURLResponse) {
        try await postmanSession.dataTask(
            for: PostmanEchoClient.ExampleGetCall()
        )
    }
}
