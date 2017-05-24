import Foundation

public protocol FakeResultProvider {
    func resultFor<C: Call>(call: C) -> URLSessionTaskResult
}

public class FakeSession<C: Client>: Session<C> {
    var resultProvider: FakeResultProvider
    
    public init(with client: C, resultProvider: FakeResultProvider) {
        self.resultProvider = resultProvider
        
        super.init(with: client)
    }
    
    override public func dataTask<C : Call>(for call: C, completion: @escaping (Result<C.ResponseType>) -> ()) -> SessionTask<C> {
        let sessionResult = resultProvider.resultFor(call: call)

        return FakeSessionTask(result: sessionResult, client: client, call: call, completion: completion)
    }
}

public class FakeSessionTask<C: Call>: SessionTask<C> {
    let result: URLSessionTaskResult

    public override var urlSessionTask: URLSessionDataTask {
        return FakeURLSessionDataTask {
            let res = self.transform(sessionResult: self.result)

            DispatchQueue.main.async {
                self.completion(res)
            }
        }
    }

    public init(result: URLSessionTaskResult, client: Client, call: C, completion: @escaping CompletionBlock) {
        self.result = result
        super.init(client: client, call: call, completion: completion)
    }
}

public class FakeHTTPURLResponse: HTTPURLResponse {
    let fakeTextEncodingName: String?

    public override var textEncodingName: String? {
        if let fakeTextEncodingName = fakeTextEncodingName {
            return fakeTextEncodingName
        }
        return fakeTextEncodingName
    }

    public init(status code: Int=200, header: Parameters?=nil, textEncodingName: String?) {
        fakeTextEncodingName = textEncodingName
        super.init(url: URL(string: "http://127.0.0.1")!, statusCode: code, httpVersion: nil, headerFields: header)!
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public class FakeURLSessionDataTask: URLSessionDataTask {
    let completion: ()->()

    init(completion: @escaping ()->()) {
        self.completion = completion
    }

    public override func resume() {
        completion()
    }
}
