import UIKit
import Endpoints
import ExampleCore

extension GiphyImage: Item {
    var text: String {
        return name
    }
}

extension GiphyListResponse: ItemsResponse {
    var items: [Item] {
        return images
    }
}

class GiphySearch: PagableSearch {
    typealias CallType = GiphyClient.Search
    
    func prepareCallForFirstPage(withQuery query: String) -> CallType {
        return GiphyClient.Search(query: query, pageSize: 5, page: 0)
    }
    
    func prepareCallForNextPage(forResponse response: CallType.Parser.OutputType, fromLastCall lastCall: CallType) -> CallType? {
        guard !response.pagination.isLastPage else {
            return nil
        }
        
        var nextCall = lastCall
        nextCall.page += 1
        
        return nextCall
    }
}
