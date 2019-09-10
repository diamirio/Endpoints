import Foundation

public typealias Parameters = [String: String]

/// A type that encapsulates all data necessary to construct an `URLRequest`
/// suitable for a typical REST-API call.
///
/// You can (and should) use this instead of a plain `URLRequest`, because it's
/// usually much more convenient and easier to read.
public struct Request: URLRequestEncodable {
    public var method: HTTPMethod
    public var url: URL
    public var header: Parameters?
    public var body: Body?
    
    /// Creates a relative Request
    public init(_ method: HTTPMethod, _ path: String? = nil, query: Parameters? = nil, header: Parameters? = nil, body: Body? = nil) {
        self.init(method, url: URL(path: path, query: query), header: header, body: body)
    }
    
    /// Creates an absolute Request
    public init(_ method: HTTPMethod, url: URL, header: Parameters? = nil, body: Body? = nil) {
        self.method = method
        self.header = header
        self.body = body
        
        self.url = url
    }
    
    public var urlRequest: URLRequest {
        var urlRequest = URLRequest(url: url)
        
        urlRequest.httpMethod = method.rawValue
        urlRequest.httpBody = body?.requestData
        
        urlRequest.apply(header: body?.header)
        urlRequest.apply(header: header) //request header trumps body header
        
        return urlRequest
    }
}

public extension URL {
    
    /// `true` if `self` has no scheme.
    ///
    /// - note: Used by `AnyClient.encode` to determine if a `URLRequest` should be
    /// encoded using `self` alone (when `false`) or in combination with
    /// its `baseURL` (when `true`).
    var isRelative: Bool {
        return scheme == nil
    }
    
    /// Creates a relative URL with a given `path` and `query` Dictionary.
    init(path: String?, query: Parameters?) {
        var components = URLComponents()
        components.path = path ?? ""
        
        if let query = query {
            components.queryItems = query.map { URLQueryItem(name: $0, value: $1) }
        }
        
        self.init(string: components.url!.relativeString)!
    }
}
