import Foundation

public protocol FakeResultProvider: Sendable {
    func data<C: Call>(for call: C) async throws -> (URLResponse, Data)
}
