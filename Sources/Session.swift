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

    public func dataTask<C: Call>(for call: C, completion: @escaping (Result<C.ResponseType>)->()) -> SessionTask<C> {
        return SessionTask(client: client, call: call, urlSession: urlSession, debug: debug, completion: completion)
    }
}

public class SessionTask<C: Call> {
    public typealias ValueType = C.ResponseType
    public typealias CompletionBlock = (Result<ValueType>)->()

    public var debug: Bool

    public let urlSession: URLSession
    public let client: Client
    public let call: C

    public private(set) lazy var urlSessionTask: URLSessionDataTask = {
        let request = self.client.encode(call: self.call)
        return self.urlSession.dataTask(with: request,
                                        completionHandler: self.completionHandler)
    }()

    public let completion: CompletionBlock

    public init(client: Client, call: C, urlSession: URLSession = URLSession.shared, debug: Bool=false, completion: @escaping CompletionBlock) {
        self.urlSession = urlSession
        self.client = client
        self.call = call
        self.debug = debug
        self.completion = completion
    }

    private func completionHandler(data: Data?, response: URLResponse?, error: Error?) {
        let sessionResult = URLSessionTaskResult(response: response, data: data, error: error)

        #if DEBUG
            if self.debug {
                print("\(urlSessionTask.requestDescription)\n\(sessionResult)")
            }
        #endif

        let result = transform(sessionResult: sessionResult)

        DispatchQueue.main.async {
            self.completion(result)
        }
    }

    public func transform(sessionResult: URLSessionTaskResult) -> Result<ValueType> {
        var result = Result<C.ResponseType>(response: sessionResult.httpResponse)

        do {
            result.value = try client.decode(sessionTaskResult: sessionResult, for: call)
        } catch {
            result.error = error
        }

        return result
    }
}
