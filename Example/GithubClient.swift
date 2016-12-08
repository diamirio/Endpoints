import Foundation
import Endpoints
import Unbox
import EndpointsUnbox

class GithubClient: BaseClient {
    var user: BasicAuthorization?
    
    init() {
        super.init(baseURL: URL(string: "https://api.github.com/")!)
    }
    
    override func encode<C : Call>(call: C) -> URLRequest {
        var request = super.encode(call: call)
        
        if let user = user {
            request.setValue(user.key, forHTTPHeaderField: user.value)
        }
        return request
    }
}

extension GithubClient {
    struct SearchRepositories: Call {
        enum Sort: String {
            case stars, forks, updated
        }
        
        enum Endpoint {
            case query(String, sort: Sort)
            case url(URL)
        }
        
        typealias ResponseType = RepositoriesResponse
        
        var endpoint: Endpoint
        
        var request: URLRequestEncodable {
            switch endpoint {
            case .query(let query, let sort):
                return Request(.get, "search/repositories", query: ["q": query, "sort": sort.rawValue])
            case .url(let url):
                return url
            }
        }
    }
}

struct Repository: Unboxable {
    let name: String
    let description: String
    let url: URL
    
    init(unboxer: Unboxer) throws {
        name = try unboxer.unbox(key: "name")
        description = try unboxer.unbox(key: "description")
        url = try unboxer.unbox(key: "html_url")
    }
}

protocol Pagable {
    var nextPage: URL? { get set }
}

extension ResponseParser where OutputType: Pagable {
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

struct RepositoriesResponse: UnboxableParser, Pagable {
    let totalCount: Int
    let repositories: [Repository]
    var nextPage: URL?
    
    init(unboxer: Unboxer) throws {
        totalCount = try unboxer.unbox(key: "total_count")
        repositories = try unboxer.unbox(key: "items")
    }
}

enum LinkRelation: String {
    case next
}

struct Link {
    var url: URL
    var rel: LinkRelation
}

extension HTTPURLResponse {
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
