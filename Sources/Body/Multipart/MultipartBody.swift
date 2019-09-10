import Foundation

/// A Body for a multipart/form-data conforming to RFC 2046
public struct MultipartBody: Body {

    /// CRLF (Carriage Return + Line Feed)
    private static let lineEnd = "\r\n"

    /// The default implementation of a `MultipartBodyPart` that accepts any combination for it's properties
    public struct Part: MultipartBodyPart {
        public let name: String
        public let filename: String?
        public let mimeType: String?
        public let charset: String?
        public let data: Data

        public init(name: String, data: Data, filename: String? = nil, mimeType: String? = nil, charset: String? = nil) {
            self.name = name
            self.data = data
            self.filename = filename
            self.mimeType = mimeType
            self.charset = charset
        }
    }

    /// The boundary without the two hyphens and CRLF
    public let boundary: String

    /// The parts of the body
    public var parts: [MultipartBodyPart]

    /// Creates a multipart body with the given parts
    ///
    /// - Parameter parts: the parts of the multipart body, as per rfc1341 there must be at least 1 part
    /// - Parameter boundary: the boundary of the multipart request, excluding the two hyphens and CRLF. Must not be longer than 70 characters.
    public init(parts: [MultipartBodyPart], boundary: String = UUID().uuidString) {
        self.parts = parts
        self.boundary = boundary
    }

    public var header: Parameters? {
        return [ "Content-Type": "multipart/form-data; boundary=\(boundary)" ]
    }

    public var requestData: Data {
        var data = Data()

        // See RFC 2046 5.1:
        // The Content-Type field for multipart entities requires one parameter, "boundary".
        // The boundary delimiter line is then defined as a line consisting entirely of two hyphen characters ("-", decimal value 45)
        // followed by the boundary parameter value from the Content-Type header field, optional linear whitespace, and a terminating CRLF.
        // Boundary delimiters must not appear within the encapsulated material, and must be no longer than 70 characters, not counting the two leading hyphens.
        let partBoundaryPrefix = "--\(boundary)\(MultipartBody.lineEnd)"

        for part in parts {

            // build header of part-entity
            data.append(string: partBoundaryPrefix)
            data.append(string: part.dispositionString)
            data.append(string: MultipartBody.lineEnd)

            if let contentTypeString = part.contentTypeString {
                data.append(string: contentTypeString)
                data.append(string: "\(MultipartBody.lineEnd)")
            }

            // build body of part-entity
            data.append(string: "\(MultipartBody.lineEnd)")
            data.append(part.data)
            data.append(string: "\(MultipartBody.lineEnd)")
        }

        // See RFC 2046 5.1:
        // The boundary delimiter line following the last body part is a distinguished delimiter that indicates
        // that no further body parts will follow. Such a delimiter line is identical to the previous delimiter lines,
        // with the addition of two more hyphens after the boundary parameter value.
        data.append(string: "--\(boundary)--")

        return data
    }
}

private extension Data {
    mutating func append(string: String) {
        append(string.data(using: .utf8)!)
    }
}
