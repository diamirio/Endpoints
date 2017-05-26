import Foundation

public class DecodingTask<D> {
    public typealias DecodingBlock = (URLSessionTaskResult) throws -> D
    public typealias CompletionBlock = (DecodedResult<D>)->()

    public let request: URLRequest
    public let decode: DecodingBlock

    public var completion: CompletionBlock
    public var debug = false

    public var urlSession = URLSession.shared

    public private(set) var activeURLSessionTask: URLSessionTask?

    public convenience init<C: Call>(call: C, completion: @escaping CompletionBlock) where C.DecodedType == D {
        self.init(request: call.request.urlRequest, decode: call.decode, completion: completion)
    }

    public init(request: URLRequest, decode: @escaping DecodingBlock, completion: @escaping CompletionBlock){
        self.request = request
        self.decode = decode
        self.completion = completion
    }

    @discardableResult
    public func start() -> URLSessionTask {
        precondition(activeURLSessionTask == nil)

        let urlSessionTask  = urlSession.dataTask(with: request, completionHandler: completionHandler)
        urlSessionTask.resume()

        activeURLSessionTask = urlSessionTask

        return urlSessionTask
    }

    public func cancel() {
        activeURLSessionTask?.cancel()
    }

    private func completionHandler(data: Data?, response: URLResponse?, error: Error?) {
        let sessionResult = URLSessionTaskResult(response: response, data: data, error: error)

        #if DEBUG
            if debug {
                print("\(activeURLSessionTask?.requestDescription ?? "?")\n\(sessionResult)")
            }
        #endif

        let result = DecodedResult { try decode(sessionResult) }

        DispatchQueue.main.async {
            self.completion(result)
        }
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

    public func dataTask<C: Call>(for call: C, completion: @escaping (DecodedResult<C.DecodedType>)->()) -> DecodingTask<C.DecodedType> {
        let cc = ClientCall(client: client, call: call)
        let task = DecodingTask(call: cc, completion: completion)
        task.urlSession = urlSession
        task.debug = debug

        return task
    }

    @discardableResult
    public func start<C: Call>(call: C, completion: @escaping (DecodedResult<C.DecodedType>)->()) -> URLSessionTask {
        let tsk = dataTask(for: call, completion: completion)

        return tsk.start()
    }
}

public struct ClientCall<C: Call>: Call {
    public typealias DecoderType = C.DecoderType

    public let client: Client
    public let call: C

    public init(client: Client, call: C) {
        self.client = client
        self.call = call
    }

    public var request: URLRequestEncodable {
        return client.encode(call: call)
    }

    public func decode(result: URLSessionTaskResult) throws -> DecodedType {
        return try client.decode(result: result, for: call)
    }
}

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

    public var isSuccess: Bool {
        return value != nil
    }

    public var isError: Bool {
        return error != nil
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
