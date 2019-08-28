import Foundation

public protocol FakeResultProvider {
    func resultFor<C: Call>(call: C) -> URLSessionTaskResult
}
