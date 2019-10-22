import Foundation
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
    
    public func parse<C : Call>(sessionTaskResult result: URLSessionTaskResult, for call: C) throws -> C.Parser.OutputType {
        do {
            // use `AnyClient` to parse the response
            // if this fails, try to read error details from response body
            return try anyClient.parse(sessionTaskResult: result, for: call)
        } catch {
            // see if the backend sent detailed error information
            guard
                let response = result.httpResponse,
                let data = result.data,
                let errorDict = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String : Any],
                let meta = errorDict["meta"] as? [String: Any],
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
    struct Search: GiphyCall {
        public typealias Parser = JSONParser<GiphyListResponse>
        
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

public struct GiphyListResponse: Decodable {
    
    public let images: [GiphyImage]
    public let pagination: GiphyPagination

    private enum CodingKeys: String, CodingKey {
        case images = "data"
        case pagination = "pagination"
    }
}

public struct GiphyPagination: Decodable {
    public var count: Int
    public var totalCount: Int
    public var offset: Int
    
    public var isLastPage: Bool {
        return offset + count >= totalCount
    }

    private enum CodingKeys: String, CodingKey {
        case count
        case totalCount = "total_count"
        case offset
    }
}

public struct GiphyImage: Decodable {

    private struct Images: Decodable {
        let downsized: Image
    }

    private struct Image: Decodable {
        let url: URL
        let width: String
        let height: String
    }

    public let name: String
    public let url: URL
    public let size: CGSize

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .slug)

        let images = try container.decode(Images.self, forKey: .images)
        url = images.downsized.url

        guard let width = Int(images.downsized.width) else {
            throw DecodingError.typeMismatch(
                Int.self,
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Decoding width: expected to decode an Int (as a String), but the String was not convertible to Int. Value: \(images.downsized.width)")
            )
        }

        guard let height = Int(images.downsized.height) else {
            throw DecodingError.typeMismatch(
                Int.self,
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Decoding height: expected to decode an Int (as a String), but the String was not convertible to Int. Value: \(images.downsized.height)")
            )
        }

        size = CGSize(width: width, height: height)
    }

    private enum CodingKeys: String, CodingKey {
        case slug
        case images
    }
}
