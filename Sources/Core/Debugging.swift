import Foundation

public extension URLRequestEncodable {
    var cURLRepresentation: String {
        return cURLRepresentation(prettyPrinted: true)
    }
    
    func cURLRepresentation(prettyPrinted: Bool, bodyEncoding: String.Encoding = .utf8) -> String {
        let r = urlRequest
        var curl = ["$ curl -i"]
        
        if let httpMethod = r.httpMethod {
            curl.append("-X \(httpMethod)")
        }
        
        r.allHTTPHeaderFields?.forEach {
            curl.append("-H \"\($0): \($1)\"")
        }
        
        var body = "" //always add -d parameter, so curl appends Content-Length header
        if let bodyData = r.httpBody {
            if var bodyString = String(data: bodyData, encoding: bodyEncoding) {
                bodyString = bodyString.replacingOccurrences(of: "\\\"", with: "\\\\\"")
                bodyString = bodyString.replacingOccurrences(of: "\"", with: "\\\"")
            
                body = bodyString
            } else {
                body = "<binary data (\(bodyData)) not convertible to \(bodyEncoding)>"
            }
        }
        curl.append("-d \"\(body)\"")
        
        if let urlString = r.url?.absoluteString {
            curl.append("\"\(urlString)\"")
        } else {
            curl.append("\"no absolute url - \(String(describing: r.url))\"")
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
        
        var s = "\(resp.statusCode)\n"
        
        httpResponse?.allHeaderFields.forEach {
            s.append("-\($0): \($1)\n")
        }
        
        if let data = data, let string = String(data: data, encoding: resp.stringEncoding) {
            if string.isEmpty {
                s.append("<empty>")
            } else {
                s.append("\(string)")
            }
        } else {
            s.append("<no data>")
        }
        return s
    }
}

public extension URLSessionTask {
    var requestDescription: String {
        guard let originalRequest = originalRequest, let realRequest = currentRequest else {
            return "<task not started yet>"
        }

        var string = ""
        if originalRequest != realRequest {
            string = "\(originalRequest.cURLRepresentation)\n-> redirected to ->\n"
        }
        string += "\(realRequest.cURLRepresentation)"

        return string
    }
}
