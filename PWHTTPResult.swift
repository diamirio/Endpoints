//
//  PWHTTPResult.swift
//  Pods
//
//  Created by Thomas Koller on 04/10/16.
//
//

import Foundation
import Alamofire
import HTTPStatusCodes

public struct PWHTTPResult<Value: DataParsable> {
    public let request: PWHTTPRequest<Value>
    public private(set) var value: Value?
    public private(set) var error: Error?
    
    public var URLResponse: HTTPURLResponse? {
        return request.activeRequest?.response
    }
    
    public var statusCode : HTTPStatusCode? = nil
    
    public var isSuccess: Bool {
        return !isError
    }
    
    public var isError: Bool {
        return error != nil
    }
    
    public init(request: PWHTTPRequest<Value>, error: Error) {
        self.request = request
        self.error = error
    }
    
    public init(request: PWHTTPRequest<Value>, value: Value) {
        self.request = request
        self.value = value
    }
    
    //FIXME: If-modified needs other initalizer
    public init(request: PWHTTPRequest<Value>) {
        self.request = request
    }
}
