// Copyright © 2023 DIAMIR. All Rights Reserved.

import Endpoints
import Foundation
import Testing

// Helper struct for running API calls within tests.
struct ClientTester<CL: Client> {
    var session: Session<CL>

    init(client: CL) {
        self.session = Session(with: client)
        session.debug = true
    }

    func performTest<C: Call>(
        call: C
    ) async throws -> (C.Parser.OutputType, HTTPURLResponse) {
        try await session.dataTask(for: call)
    }
}
