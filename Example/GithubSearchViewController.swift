import Foundation
import UIKit
import Endpoints

/*extension Repository: Item {
    var text: String {
        return name
    }
}

extension RepositoriesResponse: ItemsResponse {
    var items: [Item] {
        return repositories
    }
}*/

/*class GithubRepoSearch: PagableSearch {
    typealias CallType = GithubClient.SearchRepositories

    func prepareCallForFirstPage(withQuery query: String) {
        nextCall = GithubClient.SearchRepositories(endpoint: .query(query, sort: .stars))
    }
    
    func prepareCallForNextPage(forResponse response: CallType.ResponseType.OutputType, fromLastCall lastCall: CallType) {
        if let nextPage = response.nextPage {
            nextCall = GithubClient.SearchRepositories(endpoint: .url(nextPage))
        } else {
            nextCall = nil
        }
    }
    
    var nextCall: CallType?
}*/
