// Copyright © 2023 DIAMIR. All Rights Reserved.

import Foundation

/// Wraps an HTTP error code.
public enum StatusCodeError: LocalizedError {
	/// Describes an unacceptable status code for an HTTP request.
	/// Optionally, you can supply a `reason` which is then used as the
	/// `errorDescription` instead of the default string returned by
	/// `HTTPURLResponse.localizedString(forStatusCode:)`
	case unacceptable(code: Int, reason: String?)

    public var errorDescription: String? {
        switch self {
        case let .unacceptable(code, reason):
            reason ?? HTTPURLResponse.localizedString(forStatusCode: code)
        }
    }
}
