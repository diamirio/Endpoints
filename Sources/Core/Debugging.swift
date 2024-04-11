// Copyright © 2023 DIAMIR. All Rights Reserved.

import Foundation

public extension URLRequestEncodable {
    var cURLRepresentation: String {
        cURLRepresentation(prettyPrinted: true)
    }

    func cURLRepresentation(prettyPrinted: Bool, bodyEncoding: String.Encoding = .utf8) -> String {
        var curl = ["$ curl -i"]

        if let httpMethod = urlRequest.httpMethod {
            curl.append("-X \(httpMethod)")
        }

        urlRequest.allHTTPHeaderFields?.forEach {
            curl.append("-H \"\($0): \($1)\"")
        }

        var body = "" // always add -d parameter, so curl appends Content-Length header
        if let bodyData = urlRequest.httpBody {
            if var bodyString = String(data: bodyData, encoding: bodyEncoding) {
                bodyString = bodyString.replacingOccurrences(of: "\\\"", with: "\\\\\"")
                bodyString = bodyString.replacingOccurrences(of: "\"", with: "\\\"")

                body = bodyString
            } else {
                body = "<binary data (\(bodyData)) not convertible to \(bodyEncoding)>"
            }
        }
        curl.append("-d \"\(body)\"")

        if let urlString = urlRequest.url?.absoluteString {
            curl.append("\"\(urlString)\"")
        } else {
            curl.append("\"no absolute url - \(String(describing: urlRequest.url))\"")
        }

        return curl.joined(separator: prettyPrinted ? " \\\n\t" : " ")
    }
}

extension URLSessionTaskResult: CustomDebugStringConvertible {
    public var debugDescription: String {
        guard let resp = httpResponse else {
            let msg = error?.localizedDescription ?? "<no error>"
            return "no response. error: \(msg)"
        }

        var description = "\(resp.statusCode)\n"

        httpResponse?.allHeaderFields.forEach {
            description.append("-\($0): \($1)\n")
        }

        if let data, let string = String(data: data, encoding: resp.stringEncoding) {
            if string.isEmpty {
                description.append("<empty>")
            } else {
                description.append("\(string)")
            }
        } else {
            description.append("<no data>")
        }
        return description
    }
}

public extension HTTPURLResponse {
    override var debugDescription: String {
        var description = "\(statusCode)\n"

        allHeaderFields.forEach {
            description.append("-\($0): \($1)\n")
        }

        return description
    }
}

public extension Data {
    func debugDescription(encoding: String.Encoding) -> String {
        var description = ""

        if let string = String(data: self, encoding: encoding) {
            if string.isEmpty {
                description.append("<empty>")
            } else {
                description.append("\(string)")
            }
        } else {
            description.append("<no data>")
        }

        return description
    }
}
