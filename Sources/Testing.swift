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
    
    override public func dataTask<C : Call>(for call: C, completion: @escaping (Result<C.ResponseType.OutputType>) -> ()) -> URLSessionDataTask {
        let sessionResult = resultProvider.resultFor(call: call)
        let result = transform(sessionResult: sessionResult, for: call)
        
        return FakeURLSessionDataTask {
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
}

public class FakeHTTPURLResponse: HTTPURLResponse {
    public init(status code: Int=200, header: Parameters?=nil) {
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
