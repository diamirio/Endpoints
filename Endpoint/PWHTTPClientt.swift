//
//  PWHTTPClientt.swift
//  Pods
//
//  Created by Thomas Koller on 04/10/16.
//
//

import Foundation
import Alamofire
import HTTPStatusCodes

public class PWHTTPClient: SessionManager {
    public var logAllRequests = true
    public var logAllResponseStrings = true
    
    public func start<T: Any>(request: PWHTTPRequest<T>, logRequest: Bool=false, logResponseString: Bool=false) -> Alamofire.Request {
        let r = self.request(request)
        request.activeRequest = r
        
        if logRequest || logAllRequests {
            print("\(r.debugDescription)")
        }
        
        r.response { responseResult in
            var statusCode : HTTPStatusCode? = nil
            
            //just for debugging
            if logResponseString || self.logAllResponseStrings {
                if let data = responseResult.data, let string = String(data: data, encoding: String.Encoding.utf8) {
                    let str = string as NSString
                    print("response string for \(r) with status: \(responseResult.response?.statusCode):\n\(str)")
                } else {
                    print("no response string for \(r). error: \(responseResult.error). status: \(responseResult.response?.statusCode)")
                }
            }
            
            if let resp = responseResult.response, let status = resp.statusCodeValue {
                statusCode = status
            }
            
            var error = responseResult.error
            if let resp = responseResult.response, let status = resp.statusCodeValue , status.isError  {
                var serverMessage = resp.allHeaderFields["X-Error-Message"] as? String
                serverMessage = serverMessage?.removingPercentEncoding
                
                error = PWHTTPError.serverError(description: serverMessage ?? status.localizedReasonPhrase)
            }
            
            if let error = error {
                //bailout with error
                var result: PWHTTPResult<T> = PWHTTPResult(request: request, error: error)
                result.statusCode = statusCode
                request.completion(result)
                return
            }
            
            //no network error + no server error => PARSE
            let resp = responseResult.response! //we definitely have a response
            
            //If not modified return empty result
            if statusCode == .notModified {
                var result = PWHTTPResult(request: request)
                result.statusCode = statusCode
                request.completion(result)
                
                return
             }
            
            var result: PWHTTPResult<T>
            do {
                let object = try T.parse(data: responseResult.data, encoding: resp.encoding) as! T
                result = PWHTTPResult(request: request, value: object)
            } catch {
                result = PWHTTPResult(request: request, error: error as NSError)
            }
            result.statusCode = statusCode
            request.completion(result)
        }
        
        return r
    }
}

extension PWHTTPRequest {
    //convenience: start with default client
    public func start(logRequest: Bool=false, logResponseString: Bool=false) {
        _ = PWHTTPClient().start(request: self, logRequest: logRequest, logResponseString: logResponseString)
    }
}
