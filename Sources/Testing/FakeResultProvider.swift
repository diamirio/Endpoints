import Foundation

public protocol FakeResultProvider {
	func data<C: Call>(for call: C) async throws -> (URLResponse, Data)
}
