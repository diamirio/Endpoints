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
        // TODO: implement?
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
            
            guard let response = response as? HTTPURLResponse else {
                throw EndpointsError(
                    error: EndpointsParsingError.invalidData(description: "Response was not a valid HTTPURLResponse"),
                    response: nil
                )
            }
            
            if let error = result.error {
                throw EndpointsError(
                    error: error,
                    response: response
                )
            }
            
            guard let value = result.value else {
                throw EndpointsError(
                    error: EndpointsParsingError.invalidData(description: "Expected a parsed response body but value is nil"),
                    response: response
                )
            }

            return (value, response)
        } catch {
            let sessionResult = URLSessionTaskResult(response: nil, data: nil, error: error)
            let result = try await transform(sessionResult: sessionResult, for: call)
            
            if let error = result.error {
                throw error
            } else {
                throw HttpError.general
            }
        }
    }
    
    private struct HttpResult<C: Call> {
        let value: C.Parser.OutputType
        let response: HTTPURLResponse
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
