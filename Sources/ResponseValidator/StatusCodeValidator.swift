// Copyright © 2023 DIAMIR. All Rights Reserved.

import Foundation

/// A type validating the status code of `HTTPURLResponse`.
public class StatusCodeValidator: ResponseValidator {
	/// Checks if an HTTP status code is acceptable
	/// - returns: `true` if `code` is between 200 and 299.
	public func isAcceptableStatus(code: Int) -> Bool {
		(200 ..< 300).contains(code)
	}

	/// - throws: `StatusCodeError.unacceptable` with `reason` set to `nil`
	public func validate(
		response: HTTPURLResponse?,
		data _: Data?
	) throws {
		if let code = response?.statusCode,
		   !isAcceptableStatus(code: code) {
			throw StatusCodeError.unacceptable(code: code, reason: nil)
		}
	}
}
