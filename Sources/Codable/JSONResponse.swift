import Foundation

/// A `JSONResponse` is a type which can provide a `decoder` to decode a Network response
public protocol JSONResponse {
    static var decoder: JSONDecoder { get }
}

extension JSONResponse {
    public static var decoder: JSONDecoder {
        return JSONDecoder()
    }
}
