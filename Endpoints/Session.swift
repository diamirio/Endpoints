import Foundation

public struct Result<Value> {
    public var value: Value?
    public var error: Error?
    
    public let response: HTTPURLResponse?
    
    public var urlError: URLError? {
        return error as? URLError
    }
    
    public var wasCancelled: Bool {
        return urlError?.code == .cancelled
    }
    
    public init(response: HTTPURLResponse?) {
        self.response = response
    }
    
    @discardableResult
    public func onSuccess(block: (Value)->()) -> Result {
        if let value = value {
            block(value)
        }
        return self
    }
    
    @discardableResult
    public func onError(block: (Error)->()) -> Result {
        if !wasCancelled, let error = error {
            block(error)
        }
        return self
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
                let status = sessionResult.httpResponse?.statusCode
                if let data = data, let string = String(data: data, encoding: String.Encoding.utf8) {
                    print("response string for \(urlRequest) with status: \(status):\n\(string)")
                } else {
                    print("no response string for \(urlRequest). error: \(error). status: \(status)")
                }
            }
            
            let result = self.transform(sessionResult: sessionResult, for: call)
            
            DispatchQueue.main.async {
                completion(result)
            }
        }
        task.resume()
        
        return task
    }
    
    func transform<C: Call>(sessionResult: URLSessionTaskResult, for request: C) -> Result<C.ResponseType.OutputType> {
        var result = Result<C.ResponseType.OutputType>(response: sessionResult.httpResponse)
        
        do {
            result.value = try client.parse(sessionTaskResult: sessionResult, for: request)
        } catch {
            result.error = error
        }
        
        return result
    }
}
