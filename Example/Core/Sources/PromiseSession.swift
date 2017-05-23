import Foundation
import Endpoints
import PromiseKit

public class PromiseSession<C: Client> {
    public var debug = false
    
    public var urlSession: URLSession
    public let client: C
    
    public init(with client: C, using urlSession: URLSession=URLSession.shared) {
        self.client = client
        self.urlSession = urlSession
    }
    
    public func start<C: Call>(call: C) -> Promise<C.ResponseType> {
        return Promise { fulfill, reject in
            let urlRequest = client.encode(call: call)
            let task = urlSession.dataTask(with: urlRequest) {  data, response, error in
                do {
                    let value = try self.client.parse(sessionTaskResult: URLSessionTaskResult(response: response, data: data, error: error), for: call)
                    
                    fulfill(value)
                } catch {
                    reject(error)
                }
            }
            task.resume()
        }
    }
}
