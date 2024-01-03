// Copyright © 2023 DIAMIR. All Rights Reserved.

import Foundation

// TODO: check if still needed
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
