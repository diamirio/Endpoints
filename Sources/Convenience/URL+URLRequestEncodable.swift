import Foundation

extension URL: URLRequestEncodable {
    public var urlRequest: URLRequest {
        return URLRequest(url: self)
    }
}
