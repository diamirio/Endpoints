//
//  AsyncSession.swift
//  
//
//  Created by Dominik Arnhof on 06.12.22.
//

import Foundation

#if compiler(>=5.5) && canImport(_Concurrency)

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0,  *)
public class AsyncSession<C: AsyncClient> {
    public var debug = false
    
    public var urlSession: URLSession
    public let client: C
    
    public init(with client: C, using urlSession: URLSession=URLSession.shared) {
        self.client = client
        self.urlSession = urlSession
    }
    
    public func dataTask<C: Call>(for call: C) async throws -> HTTPURLResponse? where C.Parser.OutputType == Void  {
        return nil
    }
    
    public func dataTask<C: Call>(for call: C) async throws -> (C.Parser.OutputType, HTTPURLResponse) {
        let urlRequest = try await client.encode(call: call)
        
        do {
            let (data, response) = try await urlSession.data(for: urlRequest)
            
            let sessionResult = URLSessionTaskResult(response: response, data: data, error: nil)
            
            if debug {
                print("\(urlRequest.cURLRepresentation)\n\(sessionResult)")
            }
            
            let result = try await transform(sessionResult: sessionResult, for: call)
            
            if let value = result.value {
                guard let response = response as? HTTPURLResponse else {
                    throw HttpError.NoResponse
                }
                
                return (value, response)
            } else if let error = result.error {
                throw error
            } else {
                throw HttpError.NoResponse
            }
        } catch {
            let sessionResult = URLSessionTaskResult(response: nil, data: nil, error: error)
            
            let result = try await transform(sessionResult: sessionResult, for: call)
            
            if let error = result.error {
                throw error
            } else {
                throw HttpError.NoResponse
            }
        }
        
//        weak var tsk: URLSessionDataTask?
//        let task = urlSession.dataTask(with: urlRequest) { data, response, error in
//            let sessionResult = URLSessionTaskResult(response: response, data: data, error: error)
//
//            if let tsk = tsk, self.debug {
//                print("\(tsk.requestDescription)\n\(sessionResult)")
//            }
//
//            let result = self.transform(sessionResult: sessionResult, for: call)
//
//            DispatchQueue.main.async {
//                completion(result)
//            }
//        }
//        tsk = task //keep a weak reference for debug output
//
//        return task
        
        
//        var cancelledBeforeStart = false
//        var task: URLSessionDataTask?
//
//        let cancelTask = {
//            cancelledBeforeStart = true
//            task?.cancel()
//        }
//
//        let result = try await withTaskCancellationHandler(
//            operation: {
//                try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<HttpResult<C>, Error>) in
//                    if cancelledBeforeStart {
//                        return
//                    }
//
//                    task = dataTask(for: call, completion: { result in
//                        result.onSuccess { response in
//                            guard let response = result.response,
//                                  let body = result.value
//                            else {
//                                continuation.resume(throwing: HttpError.NoResponse)
//                                return
//                            }
//
//                            continuation.resume(returning: HttpResult(value: body, response: response))
//                        }.onError { error in
//                            continuation.resume(throwing: error)
//                        }
//                    })
//
//                    task?.resume()
//                })
//            }, onCancel: {
//                cancelTask()
//            }
//        )
//
//        return (result.value, result.response)
    }
    
    private struct HttpResult<C: Call> {
        let value: C.Parser.OutputType
        let response: HTTPURLResponse
    }
    
    enum HttpError: Error {
        case NoResponse
    }
    
    func transform<C: Call>(sessionResult: URLSessionTaskResult, for call: C) async throws -> Result<C.Parser.OutputType> {
        var result = Result<C.Parser.OutputType>(response: sessionResult.httpResponse)

        do {
            result.value = try await client.parse(sessionTaskResult: sessionResult, for: call)
        } catch {
            result.error = error
        }

        return result
    }
}

#endif
