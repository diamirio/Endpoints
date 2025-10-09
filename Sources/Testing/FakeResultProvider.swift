import Foundation

public protocol FakeResultProvider: Sendable {
    func data(for call: some Call) async throws -> (URLResponse, Data)
}
