import Foundation

public extension Session {
    @discardableResult
    func start<C: Call>(call: C, completion: @escaping (Result<C.Parser.OutputType>) -> Void) -> URLSessionDataTask {
        let tsk = dataTask(for: call, completion: completion)
        tsk.resume()
        return tsk
    }
    
#if compiler(>=5.5) && canImport(_Concurrency)
    
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0,  *)
    func start<C: Call>(call: C) async throws -> Result<C.Parser.OutputType> {
        return try await dataTask(for: call)
    }

#endif
    
}
