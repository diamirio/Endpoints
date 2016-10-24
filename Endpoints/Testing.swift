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
    
    public override func start<R : Request>(request: R) -> Task<R.ResponseType.OutputType> {
        let result = resultProvider.resultFor(request: request)
        
        let task = Task<R.ResponseType.OutputType>()
        task.urlSessionDataTask = FakeURLSessionDataTask(response: result.response)
        
        do {
            let value = try client.parse(sessionTaskResult: result, for: request)
            
            self.complete { task.onSuccessBlock?(value) }
        } catch {
            self.complete { task.onErrorBlock?(error) }
        }
        
        self.complete { task.whenDoneBlock?() }
        
        return task
    }
}

public class FakeURLSessionDataTask: URLSessionDataTask {
    public override var response: URLResponse? {
        return fakeResponse
    }
    
    let fakeResponse: URLResponse?
    init(response: URLResponse?) {
        self.fakeResponse = response
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
