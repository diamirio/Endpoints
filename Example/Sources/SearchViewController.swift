import Foundation
import UIKit
import Endpoints
import SafariServices

protocol Item {
    var text: String { get }
    var url: URL { get }
}

protocol ItemsResponse {
    var items: [Item] { get }
}

protocol PagableSearch {
    associatedtype CallType: Call
    
    func prepareCallForFirstPage(withQuery query: String) -> CallType
    func prepareCallForNextPage(forResponse response: CallType.ResponseType.OutputType, fromLastCall lastCall: CallType) -> CallType?
}

class ItemCell: UITableViewCell {
}

class SearchViewController<C: Client, S: PagableSearch>: UITableViewController, UISearchBarDelegate where S.CallType.ResponseType.OutputType: ItemsResponse {
    
    lazy var searchBar: UISearchBar = {
        let sv = UISearchBar()
        sv.placeholder = "Search"
        sv.delegate = self
        return sv
    }()

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        reset()
    }
    
    lazy var goButton: UIBarButtonItem = {
        let b = UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(reset))
        
        return b
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.titleView = searchBar
        navigationItem.rightBarButtonItem = goButton

        tableView.register(ItemCell.self, forCellReuseIdentifier: ItemCell.Id)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ItemCell.Id) as! ItemCell
        cell.textLabel!.text = data[indexPath.row].text
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = data[indexPath.row]
        
        let vc = SFSafariViewController(url: item.url)
        present(vc, animated: true, completion: nil)
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (scrollView.contentOffset.y + scrollView.bounds.height + 44) > scrollView.contentSize.height && loading == false && nextCall != nil {
            loadNextPage()
        }
    }
    
    var data = [Item]()
    let session: Session<C>
    let search: S
    var nextCall: S.CallType?
    weak var activeTask: URLSessionDataTask?
    
    var loading = false {
        didSet {
            goButton.isEnabled = !loading
            UIApplication.shared.isNetworkActivityIndicatorVisible = loading
        }
    }
    
    init(client: C, search: S) {
        self.session = Session(with: client)
        self.session.debug = true
        self.search = search
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func loadNextPage() {
        guard activeTask == nil else {
            showAlert(title: "busy", message: "loading items...")
            return
        }
        
        guard let call = nextCall else {
            showAlert(title: "done", message: "nothing more to load")
            return
        }
        
        loading = true
        activeTask = session.start(call: call) { result in
            self.loading = false
            
            result.onError { error in
                print("error: \(error)")
                self.showAlert(title: "ouch", message: error.localizedDescription)
            }.onSuccess { value in
                self.data.append(contentsOf: value.items)
                self.tableView.reloadData()
                
                self.nextCall = self.search.prepareCallForNextPage(forResponse: value, fromLastCall: call)
            }
        }.urlSessionTask
    }
    
    func reset() {
        activeTask?.cancel()
        
        nextCall = search.prepareCallForFirstPage(withQuery: searchBar.text ?? "")
        
        data.removeAll()
        tableView.reloadData()
        
        loadNextPage()
    }
}
