import UIKit
import Endpoints

class GiphyCell: UITableViewCell {
    static let Id = "GiphyCell"
}

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    lazy var tableView: UITableView = {
        let tv = UITableView()
        tv.delegate = self
        tv.dataSource = self
        
        return tv
    }()
    
    lazy var searchBar: UISearchBar = {
        let sv = UISearchBar()
        sv.placeholder = "Search Giphy"
        
        return sv
    }()
    
    lazy var nextButton: UIBarButtonItem = {
        let b = UIBarButtonItem(barButtonSystemItem: .fastForward, target: self, action: #selector(loadNextPage))
        
        return b
    }()
    
    lazy var resetButton: UIBarButtonItem = {
        let b = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(reset))
        
        return b
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = resetButton
        navigationItem.titleView = searchBar
        navigationItem.rightBarButtonItem = nextButton
        
        tableView.frame = view.bounds
        tableView.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
        view.addSubview(tableView)
        
        tableView.register(GiphyCell.self, forCellReuseIdentifier: GiphyCell.Id)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: GiphyCell.Id) as! GiphyCell
        cell.textLabel!.text = data[indexPath.row].name
        return cell
    }
    
    var data = [GiphyImage]()
    var session = Session(with: GiphyClient())
    var call = GiphyClient.Search(query: "cat", pageSize: 10, page: 0)
    var activeTask: URLSessionDataTask?
    
    func loadNextPage() {
        activeTask?.cancel()
        activeTask = session.start(call: call) { result in
            result.onError { error in
                if let urlError = error as? URLError, urlError.code == .cancelled {
                    return
                }
                
                UIAlertView(title: "ouch", message: error.localizedDescription, delegate: nil, cancelButtonTitle: "OK").show()
            }.onSuccess { value in
                self.data.append(contentsOf: value.images)
                self.tableView.reloadData()
                
                self.call.page += 1
            }
        }
    }
    
    func reset() {
        call.query = searchBar.text ?? ""
        
        data.removeAll()
        call.page = 0
        
        loadNextPage()
    }
}
