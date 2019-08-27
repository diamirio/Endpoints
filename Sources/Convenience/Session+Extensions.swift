//
//  Session+Extensions.swift
//  Endpoints
//
//  Created by Robin Mayerhofer on 27.08.19.
//  Copyright © 2019 Tailored Apps. All rights reserved.
//

import Foundation

public extension Session {
    @discardableResult
    func start<C: Call>(call: C, completion: @escaping (Result<C.ResponseType.OutputType>) -> Void) -> URLSessionDataTask {
        let tsk = dataTask(for: call, completion: completion)
        tsk.resume()
        return tsk
    }
}
