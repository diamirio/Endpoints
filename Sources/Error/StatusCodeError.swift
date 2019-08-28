import Foundation

/// Wraps an HTTP error code.
public enum StatusCodeError: Error {

    /// Describes an unacceptable status code for an HTTP request.
    /// Optionally, you can supply a `reason` which is then used as the
    /// `errorDescription` instead of the default string returned by
    /// `HTTPURLResponse.localizedString(forStatusCode:)`
    case unacceptable(code: Int, reason: String?)
}

extension StatusCodeError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unacceptable(let code, let reason):
            return reason ?? HTTPURLResponse.localizedString(forStatusCode: code)
        }
    }
}
