import Foundation

public protocol MultipartBodyPart {

    /// The name (usually from the HTML form)
    ///
    /// There can be multiple parts with the same name.
    /// The value of the `name` parameter is the original field name from the form
    var name: String { get }

    /// The original name of the file to be transmitted
    ///
    /// The file name isn't mandatory for cases where the file name isn't available or is meaningless or private.
    var filename: String? { get }

    /// The mime type of the part.
    ///
    /// e.g. `application/json`, `image/jpeg`. For further information see RFC 2046
    var mimeType: String? { get }

    /// Unlike some other parameter values, the values of the charset parameter are NOT case sensitive.
    /// The default character set, which must be assumed in the absence of a charset parameter, is US-ASCII.
    ///
    /// e.g. `utf-8`. For further information see RFC 2046
    var charset: String? { get }

    /// The data of the part
    var data: Data { get }
}

extension MultipartBodyPart {
    var dispositionString: String {
        var disp = "Content-Disposition: form-data; name=\"\(name)\""

        if let filename = filename {
            disp.append("; filename=\"\(filename)\"")
        }

        return disp
    }

    var contentTypeString: String? {
        guard let mimeType = mimeType else {
            return nil
        }

        var cType = "Content-Type: \(mimeType)"

        if let charset = charset {
            cType.append("; charset=\(charset)")
        }

        return cType
    }
}
