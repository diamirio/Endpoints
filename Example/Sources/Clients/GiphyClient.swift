import Foundation
import Unbox
import Endpoints
import CoreGraphics

class GiphyClient: Client {
    private let anyClient = AnyClient(baseURL: URL(string: "https://api.giphy.com/v1/")!)
    
    var apiKey = "dc6zaTOxFJmzC"
    
    func encode<C: Call>(call: C) -> URLRequest {
        var req = anyClient.encode(call: call)
        
        req.append(query: ["api_key": apiKey])
        
        return req
    }
    
    func parse<C : Call>(sessionTaskResult result: URLSessionTaskResult, for call: C) throws -> C.ResponseType.OutputType {
        return try anyClient.parse(sessionTaskResult: result, for: call)
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

protocol GiphyCall: Call {
}

extension GiphyClient {
    struct Search: GiphyCall {
        typealias ResponseType = GiphyListResponse
        
        var query: String
        var pageSize: Int
        var page = 0
        
        var request: URLRequestEncodable {
            return Request(.get, "gifs/search",
                           query: [ "q": query,
                                    "limit": "\(pageSize)",
                                    "offset": "\(page*pageSize)"])
        }
    }
}

struct GiphyImage: Unboxable {
    var name: String
    var url: URL
    var size: CGSize
    
    init(unboxer: Unboxer) throws {
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

struct GiphyListResponse: UnboxableParser {
    var images: [GiphyImage]
    
    init(unboxer: Unboxer) throws {
        images = try unboxer.unbox(key: "data")
    }
}
