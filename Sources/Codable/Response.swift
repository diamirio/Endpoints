import Foundation

/// A `Response` is a type which can provide a `decoder` to decode a Network response
public protocol Response {
    static var decoder: JSONDecoder { get }
}

extension Response {
    public static var decoder: JSONDecoder {
        return JSONDecoder()
    }
}
