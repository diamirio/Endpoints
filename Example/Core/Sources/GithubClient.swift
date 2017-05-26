import Foundation
import Endpoints
import Unbox

// MARK: -
// MARK: Client

public class GithubClient: AnyClient {
    public var user: BasicAuthorization?
    
    public init() {
        super.init(baseURL: URL(string: "https://api.github.com/")!)
    }
    
    override public func encode<C : Call>(call: C) -> URLRequest {
        var request = super.encode(call: call)
        
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        if let user = user {
            request.setValue(user.value, forHTTPHeaderField: user.key)
        }
        return request
    }
    
    public override func validate(result: URLSessionTaskResult) throws {
        do {
            try super.validate(result: result)
        } catch {
            if let data = result.data, let githubError: GithubError = try? unbox(data: data) {
                //propagate error details received server
                throw githubError
            } else {
                //rethrow
                throw error
            }
        }
    }
}

// MARK: -
// MARK: Requests

public extension GithubClient {
    public static func searchReposUntyped(query: String) -> AnyCall<RepositoriesResponse> {
        return searchReposUntyped(url: Request(.get, "search/repositories", query: ["q": query]))
    }
    
    public static func searchReposUntyped(url: URLRequestEncodable) -> AnyCall<RepositoriesResponse> {
        return AnyCall<RepositoriesResponse>(url)
    }
    
    public struct SearchRepositories: Call {
        public enum Sort: String {
            case stars, forks, updated
        }
        
        public enum Endpoint {
            case query(String, sort: Sort)
            case url(URL)
        }
        
        public typealias DecodedType = RepositoriesResponse
        
        public var endpoint: Endpoint
        
        public init(endpoint: Endpoint) {
            self.endpoint = endpoint
        }
        
        public var request: URLRequestEncodable {
            switch endpoint {
            case .query(let query, let sort):
                return Request(.get, "search/repositories", query: ["q": query, "sort": sort.rawValue])
            case .url(let url):
                return url
            }
        }
    }
}

// MARK: -
// MARK: Responses

public struct Repository: Unboxable {
    public let name: String
    public let description: String?
    public let url: URL
    
    public init(unboxer: Unboxer) throws {
        name = try unboxer.unbox(key: "name")
        description = unboxer.unbox(key: "description")
        url = try unboxer.unbox(key: "html_url")
    }
}

public protocol Pagable {
    var nextPage: URL? { get set }

    static var dataDecoder: ResponseDecoder<Self> { get }
}

public extension Pagable {
    mutating func decodePagingHeader(from response: HTTPURLResponse) {
        for link in response.parseLinks() {
            if link.rel == .next {
                nextPage = link.url
            }
        }
    }
}

public extension Pagable where Self: Unboxable & ResponseDecodable {
    static var dataDecoder: ResponseDecoder<Self> {
        return decodeUnboxable
    }

    static var responseDecoder: ResponseDecoder<Self> {
        return { response, data in
            var decoded = try dataDecoder(response, data)
            decoded.decodePagingHeader(from: response)
            return decoded
        }
    }
}

public struct RepositoriesResponse: Pagable, Unboxable, ResponseDecodable {
    public let totalCount: Int
    public let repositories: [Repository]
    public var nextPage: URL?
    
    public init(unboxer: Unboxer) throws {
        totalCount = try unboxer.unbox(key: "total_count")
        repositories = try unboxer.unbox(key: "items")
    }
}

public enum LinkRelation: String {
    case next
}

public struct Link {
    var url: URL
    var rel: LinkRelation
}

public struct GithubError: Unboxable, LocalizedError {
    public var message: String
    public var details: [GithubErrorDetails]?
    
    public init(unboxer: Unboxer) throws {
        self.message = try unboxer.unbox(key: "message")
        self.details = unboxer.unbox(key: "errors")
    }
    
    public var errorDescription: String? {
        var desc = message
        
        for detail in details ?? [] {
            desc.append("\n> \(detail.field) \(detail.code)")
        }
        
        return desc
    }
}

public struct GithubErrorDetails: Unboxable {
    public var field: String
    public var code: String
    
    public init(unboxer: Unboxer) throws {
        self.field = try unboxer.unbox(key: "field")
        self.code = try unboxer.unbox(key: "code")
    }
}

public extension HTTPURLResponse {
    public func parseLinks() -> [Link] {
        guard let linkHeader = self.allHeaderFields["Link"] as? String else {
            return [Link]()
        }
        
        var whitespaceAndBrackets = CharacterSet.whitespaces
        whitespaceAndBrackets.insert(charactersIn: "<>")
        
        let quote = CharacterSet(charactersIn: "\"")
        
        var links = [Link]()
        for linkString in linkHeader.components(separatedBy: ",") {
            let linkComponents = linkString.components(separatedBy: ";").map { $0.trimmingCharacters(in: whitespaceAndBrackets) }
            
            guard linkComponents.count == 2 else {
                continue
            }
            
            guard let url = URL(string: linkComponents.first!) else {
                continue
            }
            
            let relComponents = linkComponents.last!.components(separatedBy: "=")
            
            guard relComponents.count == 2, relComponents.first! == "rel" else {
                continue
            }
            
            let relString = relComponents.last!.trimmingCharacters(in: quote)
            guard let rel = LinkRelation(rawValue: relString) else {
                continue
            }
            
            links.append(Link(url: url, rel: rel))
        }
        
        return links
    }
}
