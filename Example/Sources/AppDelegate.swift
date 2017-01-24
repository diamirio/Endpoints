import UIKit
import ExampleCore

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow()
        let startVC = StartViewController()
        let navVC = UINavigationController(rootViewController: startVC)
        navVC.isToolbarHidden = false
        window.rootViewController = navVC
        window.makeKeyAndVisible()
        
        self.window = window
        return true
    }
}

