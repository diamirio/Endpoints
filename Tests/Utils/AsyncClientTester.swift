// Copyright © 2023 DIAMIR. All Rights Reserved.

import Foundation
import XCTest
import Endpoints

class AsyncClientTester<CL: Client> {
    var session: Session<CL>
    let test: XCTestCase
    
    convenience init(test: XCTestCase, client: CL) {
        self.init(test: test, session: Session(with: client))
    }
    
    init(test: XCTestCase, session: Session<CL>) {
        self.test = test
        self.session = session
        session.debug = true
    }
    
    func test<C: Call>(
        call: C
    ) async throws -> (C.Parser.OutputType, HTTPURLResponse) {
        return try await session.dataTask(for: call)
    }
}
