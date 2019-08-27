//
//  FakeURLSessionDataTask.swift
//  Endpoints
//
//  Created by Robin Mayerhofer on 27.08.19.
//  Copyright © 2019 Tailored Apps. All rights reserved.
//

import Foundation

public class FakeURLSessionDataTask: URLSessionDataTask {
    let completion: () -> Void

    init(completion: @escaping () -> Void) {
        self.completion = completion
    }

    public override func resume() {
        completion()
    }

    public override func cancel() {
        // no-op
    }
}
