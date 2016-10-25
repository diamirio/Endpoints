//
//  Testing.swift
//  Endpoints
//
//  Created by Peter W on 19/10/2016.
//  Copyright © 2016 Tailored Apps. All rights reserved.
//

import Foundation

public protocol FakeResultProvider {
    func resultFor<R: Request>(request: R) -> URLSessionTaskResult
}

public class FakeSession<C: Client>: Session<C> {
    var resultProvider: FakeResultProvider
    
    init(with client: C, resultProvider: FakeResultProvider) {
        self.resultProvider = resultProvider
        
        super.init(with: client)
    }
    
    override public func start<R : Request>(request: R, completion: @escaping (Result<R.ResponseType.OutputType>) -> ()) -> URLSessionDataTask {
        let sessionResult = resultProvider.resultFor(request: request)
        let result = transform(sessionResult: sessionResult, for: request)
        
        DispatchQueue.main.async {
            completion(result)
        }
        
        return URLSessionDataTask()
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
