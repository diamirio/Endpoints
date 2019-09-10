import Foundation
import Endpoints

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
            if let data = result.data, let githubError: GithubError = try? GithubError.decoder.decode(GithubError.self, from: data) {
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
    static func searchReposUntyped(query: String) -> AnyCall<RepositoriesResponse> {
        return searchReposUntyped(url: Request(.get, "search/repositories", query: ["q": query]))
    }
    
    static func searchReposUntyped(url: URLRequestEncodable) -> AnyCall<RepositoriesResponse> {
        return AnyCall<RepositoriesResponse>(url)
    }
    
    struct SearchRepositories: Call {
        public enum Sort: String {
            case stars, forks, updated
        }
        
        public enum Endpoint {
            case query(String, sort: Sort)
            case url(URL)
        }
        
        public typealias ResponseType = RepositoriesResponse
        
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

public struct Repository: Decodable, Response {
    public let name: String
    public let description: String?
    public let url: URL

    private enum CodingKeys: String, CodingKey {
        case name
        case description
        case url = "html_url"
    }
}

public protocol Pagable {
    var nextPage: URL? { get set }
}

public extension ResponseParser where OutputType: Pagable {
    static func parse(response: HTTPURLResponse, data: Data) throws -> OutputType {
        var output = try self.parse(data: data, encoding: response.stringEncoding)
        
        for link in response.parseLinks() {
            if link.rel == .next {
                output.nextPage = link.url
            }
        }
        
        return output
    }
}

public struct RepositoriesResponse: DecodableParser, Response, Decodable, Pagable {

    public let totalCount: Int
    public let repositories: [Repository]
    public var nextPage: URL?

    private enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case repositories = "items"
        case nextPage = "next_page"
    }
}

public enum LinkRelation: String {
    case next
}

public struct Link {
    var url: URL
    var rel: LinkRelation
}

public struct GithubError: DecodableParser, Response, Decodable, LocalizedError {
    public let message: String
    public let details: [GithubErrorDetails]?

    public var errorDescription: String? {
        var desc = message
        
        for detail in details ?? [] {
            desc.append("\n> \(detail.field) \(detail.code)")
        }
        
        return desc
    }

    private enum CodingKeys: String, CodingKey {
        case message
        case details = "errors"
    }
}

public struct GithubErrorDetails: Decodable {
    public let field: String
    public let code: String
}

public extension HTTPURLResponse {
    func parseLinks() -> [Link] {
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
