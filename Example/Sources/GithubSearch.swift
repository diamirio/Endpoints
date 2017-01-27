import Foundation
import UIKit
import Endpoints
import ExampleCore

extension Repository: Item {
    var text: String {
        return name
    }
}

extension RepositoriesResponse: ItemsResponse {
    var items: [Item] {
        return repositories
    }
}

class GithubRepoSearchUntyped: PagableSearch {
    typealias CallType = AnyCall<RepositoriesResponse>
    
    func prepareCallForFirstPage(withQuery query: String) -> CallType {
        return GithubClient.searchReposUntyped(query: query)
    }
    
    func prepareCallForNextPage(forResponse response: CallType.ResponseType.OutputType, fromLastCall lastCall: CallType) -> CallType? {
        guard let nextPage = response.nextPage else {
            return nil
        }
        
        return GithubClient.searchReposUntyped(url: nextPage)
    }
}

class GithubRepoSearch: PagableSearch {
    typealias CallType = GithubClient.SearchRepositories
    
    var sort: GithubClient.SearchRepositories.Sort = .stars

    func prepareCallForFirstPage(withQuery query: String) -> CallType {
        return GithubClient.SearchRepositories(endpoint: .query(query, sort: sort))
    }
    
    func prepareCallForNextPage(forResponse response: CallType.ResponseType.OutputType, fromLastCall lastCall: CallType) -> CallType? {
        guard let nextPage = response.nextPage else {
            return nil
        }
        
        return GithubClient.SearchRepositories(endpoint: .url(nextPage))
    }
}

class GithubRepoSearchViewController: SearchViewController<GithubClient, GithubRepoSearch> {
    lazy var sortButton: UIBarButtonItem = {
        let btn = UIBarButtonItem(title: "Sort", style: .plain, target: self, action: #selector(sortTapped))
        return btn
    }()
    
    func sortTapped() {
        let sheet = UIAlertController(title: "Sort", message: nil, preferredStyle: .actionSheet)
        let sorts: [GithubClient.SearchRepositories.Sort] = [ .stars, .forks, .updated ]
        
        for sort in sorts {
            sheet.addAction(UIAlertAction(title: sort.rawValue, style: .default) { action in
                self.search.sort = sort
                self.updateView()
                self.reset()
            })
        }
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(sheet, animated: true, completion: nil)
    }
    
    func updateView() {
        sortButton.title = "Sort: \(search.sort.rawValue)"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateView()
    }
    
    init() {
        super.init(client: GithubClient(), search: GithubRepoSearch())
        
        toolbarItems = [ sortButton ]
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
