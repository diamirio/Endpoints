import Foundation
import Unbox
import Endpoints
import CoreGraphics

// MARK: -
// MARK: Client

public class GiphyClient: Client {
    private let anyClient = AnyClient(baseURL: URL(string: "https://api.giphy.com/v1/")!)
    
    public var apiKey = "dc6zaTOxFJmzC"
    
    public init() {}
    
    public func encode<C: Call>(call: C) -> URLRequest {
        var req = anyClient.encode(call: call)
        
        // Append the API key to every request
        req.append(query: ["api_key": apiKey])
        
        return req
    }

    public func decode<C>(result: URLSessionTaskResult, for call: C) throws -> C.ResponseType where C : Call {
        do {
            // use `AnyClient` to parse the response
            // if this fails, try to read error details from response body
            return try anyClient.decode(result: result, for: call)
        } catch {
            // see if the backend sent detailed error information
            guard
                let response = result.httpResponse,
                let data = result.data,
                let errorDict = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any],
                let meta = errorDict?["meta"] as? [String: Any],
                let errorCode = meta["error_code"] as? String else {
                // no error info from backend -> rethrow default error
                throw error
            }
            
            //propagate error that contains errorCode as reason from backend
            throw StatusCodeError.unacceptable(code: response.statusCode, reason: errorCode)
        }
    }
}

extension URLRequest {
    mutating func append(query: Parameters) {
        guard let absoluteURL = url?.absoluteURL, var comps = URLComponents(url: absoluteURL, resolvingAgainstBaseURL: false) else {
            return
        }
        
        var queryItems = comps.queryItems ?? [URLQueryItem]()
        for q in query {
            queryItems.append(URLQueryItem(name: q.key, value: q.value))
        }
        comps.queryItems = queryItems
        
        url = comps.url
    }
}

// MARK: -
// MARK: Requests

public protocol GiphyCall: Call {
}

public extension GiphyClient {
    public struct Search: GiphyCall {
        public typealias ResponseType = GiphyListResponse
        
        public var query: String
        public var pageSize: Int
        public var page: Int
        
        public init(query: String, pageSize: Int=10, page: Int=0) {
            self.query = query
            self.pageSize = pageSize
            self.page = page
        }
        
        public var request: URLRequestEncodable {
            return Request(.get, "gifs/search",
                           query: [ "q": query,
                                    "limit": "\(pageSize)",
                                    "offset": "\(page*pageSize)"])
        }
    }
}

// MARK: -
// MARK: Responses

public struct GiphyListResponse: Unboxable, ResponseDecodable {
    public var images: [GiphyImage]
    public var pagination: GiphyPagination
    
    public init(unboxer: Unboxer) throws {
        images = try unboxer.unbox(key: "data")
        pagination = try unboxer.unbox(key: "pagination")
    }
}

public struct GiphyPagination: Unboxable {
    public var count: Int
    public var totalCount: Int
    public var offset: Int
    
    public var isLastPage: Bool {
        return offset + count >= totalCount
    }
    
    public init(unboxer: Unboxer) throws {
        count = try unboxer.unbox(key: "count")
        totalCount = try unboxer.unbox(key: "total_count")
        offset = try unboxer.unbox(key: "offset")
    }
}

public struct GiphyImage: Unboxable {
    public var name: String
    public var url: URL
    public var size: CGSize
    
    public init(unboxer: Unboxer) throws {
        name = try unboxer.unbox(keyPath: "slug")
        
        let images = unboxer.dictionary["images"] as! UnboxableDictionary
        let downsized = images["downsized"] as! UnboxableDictionary
        let unboxer = Unboxer(dictionary: downsized)
        
        url = try unboxer.unbox(key: "url")
        
        let width: Int = try unboxer.unbox(key: "width")
        let height: Int = try unboxer.unbox(key: "height")
        
        size = CGSize(width: width, height: height)
    }
}
