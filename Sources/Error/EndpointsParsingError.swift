// Copyright © 2023 DIAMIR. All Rights Reserved.

import Foundation

/// Describes an error that occurs during parsing `Data`.
public enum EndpointsParsingError: LocalizedError {

    /// `Data` is missing.
    ///
    /// Thrown by `AnyClient.parse` when the response data is `nil`.
    case missingData

    /// `Data` is in an invalid format.
    ///
    /// Thrown by `DataParser` implementations.
    case invalidData(description: String)

    public var errorDescription: String? {
        switch self {
        case .missingData:
            return "no data"
        case .invalidData(let desc):
            return desc
        }
    }
}
