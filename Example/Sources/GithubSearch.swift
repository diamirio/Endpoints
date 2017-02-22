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
    
    lazy var loginButton: UIBarButtonItem = {
        let btn = UIBarButtonItem(title: "Login", style: .plain, target: self, action: #selector(loginTapped))
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
    
    func loginTapped() {
        if let _ = session.client.user {
            session.client.user = nil //logout
        } else {
            let alert = UIAlertController(title: "Login", message: nil, preferredStyle: .alert)
            alert.addTextField { txt in
                txt.placeholder = "username"
                txt.text = "iteracticman"
            }
            alert.addTextField { txt in
                txt.placeholder = "password"
                txt.isSecureTextEntry = true
            }
            alert.addAction(UIAlertAction(title: "OK", style: .default) { action in
                guard let user = alert.textFields?.first?.text, let pwd = alert.textFields?.last?.text else {
                    return
                }
                
                self.session.client.user = BasicAuthorization(user: user, password: pwd)
                self.reset()
                self.updateView()
            })
            
            present(alert, animated: true, completion: nil)
        }
    }
    
    func updateView() {
        sortButton.title = "Sort: \(search.sort.rawValue)"
        if let auth = session.client.user {
            loginButton.title = "Logout \(auth.user)"
        } else {
            loginButton.title = "Login"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateView()
    }
    
    init() {
        super.init(client: GithubClient(), search: GithubRepoSearch())
        
        toolbarItems = [ sortButton, UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil) ,loginButton ]
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
