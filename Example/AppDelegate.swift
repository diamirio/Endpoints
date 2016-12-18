import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow()
        //let searchVC = SearchViewController(client: GithubClient(), search: GithubRepoSearch())
        let searchVC = SearchViewController(client: GiphyClient(), search: GiphySearch())
        let navVC = UINavigationController(rootViewController: searchVC)
        window.rootViewController = navVC
        window.makeKeyAndVisible()
        
        self.window = window
        return true
    }
}

