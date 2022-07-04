import Foundation

public extension Session {
    @discardableResult
    func start<C: Call>(call: C, completion: @escaping (Result<C.Parser.OutputType>) -> Void) -> URLSessionDataTask {
        let tsk = dataTask(for: call, completion: completion)
        tsk.resume()
        return tsk
    }
    
    func start<C: Call>(call: C) async throws -> Result<C.Parser.OutputType> {
        return try await dataTask(for: call)
    }
}
