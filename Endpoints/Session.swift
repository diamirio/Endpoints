import Foundation

public struct Result<Value> {
    public var value: Value?
    public var error: Error?
    
    public let response: HTTPURLResponse?
    
    public init(response: HTTPURLResponse?) {
        self.response = response
    }
}

public class Session<C: Client> {
    public var debug = false
    
    public var urlSession: URLSession
    public let client: C
    
    public init(with client: C, using urlSession: URLSession=URLSession.shared) {
        self.client = client
        self.urlSession = urlSession
    }
    
    @discardableResult
    public func start<C: Call>(call: C, completion: @escaping (Result<C.ResponseType.OutputType>)->()) -> URLSessionDataTask {
        let urlRequest = client.encode(call: call)
        let task = urlSession.dataTask(with: urlRequest) { data, response, error in
            let sessionResult = URLSessionTaskResult(response: response, data: data, error: error)
            
            if self.debug {
                print("\(urlRequest.cURLRepresentation)\n\(sessionResult)")
            }
            
            let result = self.transform(sessionResult: sessionResult, for: call)
            
            DispatchQueue.main.async {
                completion(result)
            }
        }
        task.resume()
        
        return task
    }
    
    func transform<C: Call>(sessionResult: URLSessionTaskResult, for call: C) -> Result<C.ResponseType.OutputType> {
        var result = Result<C.ResponseType.OutputType>(response: sessionResult.httpResponse)
        
        do {
            result.value = try client.parse(sessionTaskResult: sessionResult, for: call)
        } catch {
            result.error = error
        }
        
        return result
    }
}
