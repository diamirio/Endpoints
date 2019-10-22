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

    public func dataTask<C: Call>(for call: C, completion: @escaping (Result<C.Parser.OutputType>) -> Void) -> URLSessionDataTask {
        let urlRequest = client.encode(call: call)
        weak var tsk: URLSessionDataTask?
        let task = urlSession.dataTask(with: urlRequest) { data, response, error in
            let sessionResult = URLSessionTaskResult(response: response, data: data, error: error)

            if let tsk = tsk, self.debug {
                print("\(tsk.requestDescription)\n\(sessionResult)")
            }

            let result = self.transform(sessionResult: sessionResult, for: call)

            DispatchQueue.main.async {
                completion(result)
            }
        }
        tsk = task //keep a weak reference for debug output

        return task
    }

    func transform<C: Call>(sessionResult: URLSessionTaskResult, for call: C) -> Result<C.Parser.OutputType> {
        var result = Result<C.Parser.OutputType>(response: sessionResult.httpResponse)

        do {
            result.value = try client.parse(sessionTaskResult: sessionResult, for: call)
        } catch {
            result.error = error
        }

        return result
    }
}
