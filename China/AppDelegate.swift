
import MonkeyKing
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func applicationDidFinishLaunching(_ application: UIApplication) {
        if true {
            clearAllLocalTokens()
        }
        
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
        return MonkeyKing.handleOpenUserActivity(userActivity)
    }

    private func clearAllLocalTokens() {
        let secItemClasses = [kSecClassGenericPassword, kSecClassInternetPassword, kSecClassCertificate, kSecClassKey, kSecClassIdentity]
        for itemClass in secItemClasses {
            let spec: NSDictionary = [kSecClass: itemClass]
            SecItemDelete(spec)
        }

        UserDefaults.standard
            .dictionaryRepresentation().keys
            .forEach(UserDefaults.standard.removeObject)
    }
}
