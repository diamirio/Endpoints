import Foundation
import Endpoints
import PromiseKit

extension Session {
    public func start<C: Call>(call: C) -> Promise<C.DecodedType> {
        return Promise { fulfill, reject in
            self.start(call: call) { result in
                if let error = result.error {
                    // reject also on cancellation
                    reject(error)
                }

                result.onSuccess { value in
                    fulfill(value)
                }
            }
        }
    }
}
