import Foundation

public extension HTTPURLResponse {

    /// Returns the `textEncodingName`s corresponding `String.Encoding`
    /// or `utf8`, if this is not possible.
    var stringEncoding: String.Encoding {
        var encoding = String.Encoding.utf8

        if let textEncodingName = textEncodingName {
            let cfStringEncoding = CFStringConvertIANACharSetNameToEncoding(textEncodingName as CFString)
            encoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(cfStringEncoding))
        }

        return encoding
    }
}
