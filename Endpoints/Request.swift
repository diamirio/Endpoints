import Foundation

public typealias Parameters = [String: String]

public enum HTTPMethod: String {
    case get     = "GET"
    case post    = "POST"
    case put     = "PUT"
    case patch   = "PATCH"
    case delete  = "DELETE"
    case head    = "HEAD"
    case options = "OPTIONS"
    case trace   = "TRACE"
    case connect = "CONNECT"
}

/// A type representing an HTTP Body.
///
/// A `Body` is used by `Request` to create an `URLRequest`.
///
/// Adopted by `Data` and `String`.
/// - seealso: `FormEncodedBody`, `JSONEncodedBody`.
public protocol Body {
    
    /// Returns HTTP Header parameters required for `self`, if any.
    ///
    /// This is usally a "Content-Type" header like "application/json" for a
    /// JSON encoded Body.
    ///
    /// Defaults to `nil`.
    var header: Parameters? { get }
    
    /// The body data that should be sent in an HTTP request.
    var requestData: Data { get }
}

extension Body {
    public var header: Parameters? { return nil }
}

extension Data: Body {
    public var requestData: Data { return self }
}

extension String: Body {
    public var requestData: Data {
        guard let data = data(using: .utf8) else {
            fatalError("cannot convert string to data: \(self)")
        }
        return data
    }
}

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
        guard let encoded = string.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            fatalError("failed to encode param string: \(string)")
        }
        return encoded
    }
}

/// A type representing a JSON encoded HTTP request body.
public struct JSONEncodedBody: Body {
    public let requestData: Data
    
    /// Initialize with a JSON object, an `Array` or a `Dictionary`.
    ///
    /// - throws: The error thrown by `JSONSerialization.data(withJSONObject:options:)`, if `jsonObject`
    /// cannot be encoded.
    public init(jsonObject: Any) throws {
        requestData = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
    }
    
    /// Returns "Content-Type": "application/json".
    public var header: Parameters? {
        return [ "Content-Type" : "application/json" ]
    }
}

/// A type that can transform itself into an `URLRequest`.
///
/// This protocol is adopted by `Request`, `URLRequest`, `URL` and `Call`.
public protocol URLRequestEncodable: CustomDebugStringConvertible {
    
    /// Returns an `URLRequest` configured with the data encapsulated by `self`.
    var urlRequest: URLRequest { get }
}

extension URLRequestEncodable {
    
    /// Returns the value returned by `cURLRepresentation`.
    public var debugDescription: String {
        return cURLRepresentation
    }
}

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
    public init(_ method: HTTPMethod, _ path: String?=nil, query: Parameters?=nil, header: Parameters?=nil, body: Body?=nil) {
        self.init(method, url: URL(path: path, query: query), header: header, body: body)
    }
    
    /// Creates an absolute Request
    public init(_ method: HTTPMethod, url: URL, header: Parameters?=nil, body: Body?=nil) {
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

public extension URLRequest {
    
    /// Adds or replaces all header fields with the given values.
    ///
    /// - note: If a value was previously set for the given header
    /// field, that value is replaced.
    mutating func apply(header: Parameters?) {
        header?.forEach { setValue($1, forHTTPHeaderField: $0) }
    }
}

public extension URL {
    
    /// `true` if `self` has no scheme.
    ///
    /// - note: Used by `BaseClient.encode` to determine if a `URLRequest` should be
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
