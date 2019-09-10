import Foundation

/// A type validating the status code of `HTTPURLResponse`.
public class StatusCodeValidator: ResponseValidator {

    /// Checks if an HTTP status code is acceptable
    /// - returns: `true` if `code` is between 200 and 299.
    public func isAcceptableStatus(code: Int) -> Bool {
        return (200..<300).contains(code)
    }

    /// - throws: `StatusCodeError.unacceptable` with `reason` set to `nil`
    /// if `result` contains an unacceptable status code.
    public func validate(result: URLSessionTaskResult) throws {
        if let code = result.httpResponse?.statusCode, !isAcceptableStatus(code: code) {
            throw StatusCodeError.unacceptable(code: code, reason: nil)
        }
    }
}
