import Foundation
import Endpoints
import Unbox
import CoreGraphics

class GiphyClient: BaseClient {
    var apiKey = "dc6zaTOxFJmzC"
    
    init() {
        super.init(baseURL: URL(string: "https://api.giphy.com/v1/")!)
    }
    
    override func encode<C: Call>(call: C) -> URLRequest {
        var req = super.encode(call: call)
        var comps = URLComponents(url: req.url!, resolvingAgainstBaseURL: false)
        var query = comps?.queryItems ?? [URLQueryItem]()
        query.append(URLQueryItem(name: "api_key", value: apiKey))
        comps?.queryItems = query
        
        req.url = comps?.url
        
        return req
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
        
        var request: Request {
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

protocol UnboxableParser: Unboxable, ResponseParser {}

extension UnboxableParser {
    static func parse(responseData: Data, encoding: String.Encoding) throws -> Self {
        return try unbox(data: responseData)
    }
}
