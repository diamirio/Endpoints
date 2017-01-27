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

extension UIViewController {
    public func showAlert(title: String, message: String="") {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
}
