import Foundation

public enum DecodedResult<Value> {
    case success(Value)
    case failure(Error)

    public init(_ block: () throws -> Value) {
        do {
            self = .success(try block())
        } catch {
            self = .failure(error)
        }
    }

    public var value: Value? {
        guard case let .success(value) = self else {
            return nil
        }
        return value
    }

    public var error: Error? {
        guard case let .failure(error) = self else {
            return nil
        }
        return error
    }

    public var urlError: URLError? {
        return error as? URLError
    }

    public var wasCancelled: Bool {
        return urlError?.code == .cancelled
    }

    public func handle(success: (Value)->(), failure: (Error)->(), cancelled: (()->())?=nil) {
        switch self {
        case .success(let value):
            success(value)
        case .failure(let error):
            if wasCancelled {
                cancelled?()
            } else {
                failure(error)
            }
        }
    }

    @discardableResult
    public func onSuccess(block: (Value)->()) -> DecodedResult {
        handle(success: block, failure: { _ in })
        return self
    }

    @discardableResult
    public func onError(block: (Error)->()) -> DecodedResult {
        handle(success: { _ in }, failure: block)
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

    public func dataTask<C: Call>(for call: C, completion: @escaping (DecodedResult<C.ResponseType>)->()) -> SessionTask<C> {
        let task = SessionTask(client: client, call: call)
        task.urlSession = urlSession
        task.completion = completion
        task.debug = debug

        return task
    }

    @discardableResult
    public func start<C: Call>(call: C, completion: @escaping (DecodedResult<C.ResponseType>)->()) -> URLSessionTask {
        let tsk = dataTask(for: call, completion: completion)
        tsk.urlSessionTask.resume()
        return tsk.urlSessionTask
    }
}

public class SessionTask<C: Call>: URLRequestEncodable {
    public typealias CompletionBlock = (DecodedResult<C.ResponseType>)->()

    public let client: Client
    public let call: C

    public var urlRequest: URLRequest {
        return client.encode(call: call)
    }

    public var completion: CompletionBlock?
    public var debug = false

    public var urlSession = URLSession.shared

    public private(set) lazy var urlSessionTask: URLSessionTask = {
        return self.createURLSessionTask()
    }()

    private func createURLSessionTask() -> URLSessionTask {
        return urlSession.dataTask(with: urlRequest, completionHandler: completionHandler)
    }

    private func completionHandler(data: Data?, response: URLResponse?, error: Error?) {
        let sessionResult = URLSessionTaskResult(response: response, data: data, error: error)

        #if DEBUG
            if self.debug {
                print("\(urlSessionTask.requestDescription)\n\(sessionResult)")
            }
        #endif

        let result = DecodedResult {
            try self.client.decode(result: sessionResult, for: call)
        }

        DispatchQueue.main.async {
            self.completion?(result)
        }
    }

    public init(client: Client, call: C) {
        self.client = client
        self.call = call
    }
}
