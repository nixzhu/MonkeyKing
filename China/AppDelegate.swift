
import MonkeyKing
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func applicationDidFinishLaunching(_ application: UIApplication) {
        MonkeyKing.registerLaunchFromWeChatMiniAppHandler { messageExt in
            print("messageExt:", messageExt)
        }
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return MonkeyKing.handleOpenURL(url)
    }

    func application(_ application: UIApplication, handleOpen url: URL) -> Bool {
        return MonkeyKing.handleOpenURL(url)
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        MonkeyKing.handleOpenUserActivity(userActivity)
        return true
    }
}
