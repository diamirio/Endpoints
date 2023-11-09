//
//  AsyncClientTester.swift
//  
//
//  Created by Dominik Arnhof on 14.12.22.
//

import Foundation
import XCTest
import Endpoints

#if compiler(>=5.5) && canImport(_Concurrency)

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0,  *)
class AsyncClientTester<CL: AsyncClient> {
    var session: AsyncSession<CL>
    let test: XCTestCase
    
    convenience init(test: XCTestCase, client: CL) {
        self.init(test: test, session: AsyncSession(with: client))
    }
    
    init(test: XCTestCase, session: AsyncSession<CL>) {
        self.test = test
        self.session = session
        session.debug = true
    }
    
    func test<C: Call>(call: C, validateResult: ((Result<C.Parser.OutputType>) -> Void)? = nil) async throws -> (C.Parser.OutputType, HTTPURLResponse) {
        return try await session.start(call: call)
    }
}

#endif
