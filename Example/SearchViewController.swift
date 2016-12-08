import Foundation
import UIKit
import Endpoints

protocol Item {
    var text: String { get }
}
/*
protocol ItemsResponse {
    var items: [Item] { get }
}*/

protocol B {
    
}

protocol PagableSearch {
    //associatedtype CallType: Y
    
    //var nextCall: CallType? { get }
    
    //func prepareCallForFirstPage(withQuery query: String)
    //func prepareCallForNextPage(forResponse response: CallType.ResponseType.OutputType, fromLastCall lastCall: CallType)
}

class X<S: PagableSearch> {
    init() {
        
    }
    var s: S?
}

class ItemCell: UITableViewCell {
    static let Id = "ItemCell"
}

class SearchViewController<C: Client>: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    lazy var tableView: UITableView = {
        let tv = UITableView()
        tv.delegate = self
        tv.dataSource = self
        
        return tv
    }()
    
    lazy var searchBar: UISearchBar = {
        let sv = UISearchBar()
        sv.placeholder = "Search"
        
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
        
        tableView.register(ItemCell.self, forCellReuseIdentifier: ItemCell.Id)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ItemCell.Id) as! ItemCell
        cell.textLabel!.text = data[indexPath.row].text
        return cell
    }
    
    var data = [Item]()
    let session: Session<C>
    //var searchable: S
    var activeTask: URLSessionDataTask?
    
    init(client: C) {
        self.session = Session(with: client)
        //self.searchable = searchable
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func loadNextPage() {
        guard activeTask == nil else {
            UIAlertView(title: "busy", message: "loading items...", delegate: nil, cancelButtonTitle: "OK").show()
            return
        }
        
//        guard let call = searchable.nextCall else {
//            UIAlertView(title: "done", message: "nothing more to load", delegate: nil, cancelButtonTitle: "OK").show()
//            return
//        }
//        
//        activeTask = session.start(call: call) { result in
//            result.onError { error in
//                UIAlertView(title: "ouch", message: error.localizedDescription, delegate: nil, cancelButtonTitle: "OK").show()
//            }.onSuccess { value in
//                //self.data.append(contentsOf: value.items)
//                self.tableView.reloadData()
//                
//                //self.searchable.prepareCallForNextPage(forResponse: value, fromLastCall: call)
//            }
//        }
    }
    
    func reset() {
        activeTask?.cancel()
        
        //searchable.prepareCallForFirstPage(withQuery: searchBar.text ?? "")
        
        data.removeAll()
        tableView.reloadData()
        
        loadNextPage()
    }
}
