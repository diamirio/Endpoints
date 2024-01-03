// Copyright © 2023 DIAMIR. All Rights Reserved.

import Foundation

/// Wrapper for errors which occur during the Endpoints session call
/// includes a possible `response` property in case one exists
public struct EndpointsError: LocalizedError {
    public let error: Error
    public let response: HTTPURLResponse?
    
    public init(error: Error, response: HTTPURLResponse?) {
        self.error = error
        self.response = response
    }
    
    public var errorDescription: String? {
        error.localizedDescription
    }
}
