
import UIKit
import DescopeKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // we fetch the required Descope config values from the project settings, but you
        // can pass constant String values to the `Descope.setup` call as well
        guard let localProjectId = Bundle.main.object(forInfoDictionaryKey: "myProjectId") as? String,
              let localBaseURL = Bundle.main.object(forInfoDictionaryKey: "myBaseURL") as? String else {
            preconditionFailure("Missing myProjectId or myBaseURL in Info.plist")
        }

        // initialize the Descope SDK before using it
        Descope.setup(projectId: localProjectId) { config in
            config.baseURL = localBaseURL
            #if DEBUG
            config.logger = DescopeLogger.debugLogger
            #else
            config.logger = nil
            #endif
        }

        // show home screen if user is already logged in, otherwise show authentication screen
        let initialViewController: UIViewController
        if let session = Descope.sessionManager.session, !session.refreshToken.isExpired {
            initialViewController = AppInterface.createHomeScreen()
        } else {
            initialViewController = AppInterface.createAuthScreen()
        }

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.tintColor = NordColor.black
        window?.rootViewController = initialViewController
        window?.makeKeyAndVisible()

        return true
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        // pass any incoming Universal Links to the current flow in case we're
        // using Magic Link authentication in the flows
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb, let url = userActivity.webpageURL else { return false }
        let handled = Descope.handleURL(url)
        return handled
    }
}
