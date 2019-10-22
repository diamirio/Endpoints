import Foundation

extension Result {
    public var urlError: URLError? {
        return error as? URLError
    }

    public var wasCancelled: Bool {
        return urlError?.code == .cancelled
    }

    @discardableResult
    public func onSuccess(block: (Value) -> Void) -> Result {
        if let value = value {
            block(value)
        }
        return self
    }

    @discardableResult
    public func onError(block: (Error) -> Void) -> Result {
        if !wasCancelled, let error = error {
            block(error)
        }
        return self
    }
}
