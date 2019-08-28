import Foundation

/// A type representing a form encoded HTTP request body.
public struct FormEncodedBody: Body {

    /// The parameters dictionary to be encoded.
    public var parameters: Parameters

    /// Initialize with a parameters dictionary.
    ///
    /// The parameters do not have to be percent encoded.
    public init(parameters: Parameters) {
        self.parameters = parameters
    }

    /// Returns "Content-Type": "application/x-www-form-urlencoded".
    public var header: Parameters? {
        return [ "Content-Type": "application/x-www-form-urlencoded" ]
    }

    /// Returns the encapsulated parameters dictionary as form encoded `Data`.
    public var requestData: Data {
        return parameters.map { key, value in
            return "\(encode(key))=\(encode(value))"
        }.joined(separator: "&").data(using: .utf8)!
    }

    /// add percent encoding to a string suitable for a form encoded request.
    func encode(_ string: String) -> String {
        // addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) does not work
        // see: https://stackoverflow.com/a/8088484
        // implementation from: https://useyourloaf.com/blog/how-to-percent-encode-a-url-string/
        let unreserved = "*-._"
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: unreserved)

        guard let encoded = string.addingPercentEncoding(withAllowedCharacters: allowed) else {
            fatalError("failed to encode param string: \(string)")
        }
        return encoded
    }
}
