// Copyright © 2023 DIAMIR. All Rights Reserved.

import Foundation

/// A type responsible for validating the result produced by a
/// `URLSession`s `completionHandler` block.
public protocol SyncResponseValidator {
	/// Validates the data provided by `URLSession`s `completionHandler`
	/// block.
	/// - throws: Any `Error`, if `result` is not valid.
	func validate(
		response: HTTPURLResponse?,
		data: Data?
	) throws
}

/// A type responsible for validating the result produced by a
/// `URLSession`s `completionHandler` block.
public protocol ResponseValidator {
	/// Validates the data provided by `URLSession`s `completionHandler`
	/// block.
	/// - throws: Any `Error`, if `result` is not valid.
	func validate(
		response: HTTPURLResponse?,
		data: Data?
	) throws
}
