import Foundation
import UIKit
import ExampleCore

extension UITableViewCell {
    static var Id: String {
        return String(describing: self)
    }
}

class StartViewController: UITableViewController {
    enum MenuItem: String {
        case github, giphy
        
        var vc: UIViewController {
            switch self {
            case .github:
                return GithubRepoSearchViewController()
            case .giphy:
                return SearchViewController(client: GiphyClient(), search: GiphySearch())
            }
        }
    }
    
    lazy var items: [MenuItem] = [ .giphy, .github ]
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.Id, for: indexPath)
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.text = items[indexPath.row].rawValue
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        navigationController?.pushViewController(items[indexPath.row].vc, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.Id)
    }
}
