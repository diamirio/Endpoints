import Foundation

/// A type responsible for validating the result produced by a
/// `URLSession`s `completionHandler` block.
public protocol ResponseValidator {

    /// Validates the data provided by `URLSession`s `completionHandler`
    /// block.
    /// - throws: Any `Error`, if `result` is not valid.
    func validate(result: URLSessionTaskResult) throws
}
