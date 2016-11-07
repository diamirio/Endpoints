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

public protocol Body {
    var header: Parameters? { get }
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

public struct FormEncodedBody: Body {
    public var parameters: Parameters
    
    public init(parameters: Parameters) {
        self.parameters = parameters
    }
    
    public var header: Parameters? {
        return [ "Content-Type" : "application/x-www-form-urlencoded" ]
    }
    
    public var requestData: Data {
        return parameters.map { key, value in
            return "\(encode(key))=\(encode(value))"
        }.joined(separator: "&").data(using: .utf8)!
    }
    
    func encode(_ string: String) -> String {
        guard let encoded = string.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            fatalError("failed to encode param string: \(string)")
        }
        return encoded
    }
}

public struct JSONEncodedBody: Body {
    public let requestData: Data
    
    public init(jsonObject: Any) throws {
        requestData = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
    }
    
    public var header: Parameters? {
        return [ "Content-Type" : "application/json" ]
    }
}


public protocol URLRequestEncodable {
    var urlRequest: URLRequest { get }
}

public struct Request: URLRequestEncodable {
    public var method: HTTPMethod
    public var url: URL
    public var header: Parameters?
    public var body: Body?
    
    public init(_ method: HTTPMethod, _ path: String?=nil, query: Parameters?=nil, header: Parameters?=nil, body: Body?=nil) {
        self.method = method
        self.header = header
        self.body = body
        
        self.url = URL(path: path, query: query)
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
    mutating func apply(header: Parameters?) {
        header?.forEach { setValue($1, forHTTPHeaderField: $0) }
    }
}

public extension URL {
    var isRelative: Bool {
        return scheme == nil
    }
    
    //creates a relative url
    init(path: String?, query: Parameters?) {
        var components = URLComponents()
        components.path = path ?? ""
        
        if let query = query {
            components.queryItems = query.map { URLQueryItem(name: $0, value: $1) }
        }
        
        self.init(string: components.url!.relativeString)!
    }
}
