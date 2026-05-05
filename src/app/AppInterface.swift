
import UIKit

/// Which authentication screen to show when the app runs.
/// Set to `.menu` to pick at runtime; otherwise launches directly into the chosen flow.
@MainActor
var appInterface = AppInterface.menu

/// The kinds of authentication screens supported by the app
@MainActor
enum AppInterface {
    /// Display a menu listing every supported authentication option
    case menu

    /// Display a native authentication view for using passkeys
    case passkeys

    /// A very simple example of authentication with flows by pushing a
    /// DescopeFlowViewController onto a UINavigationController stack
    case simpleFlow

    /// A more complex example of authentication with flows that creates a
    /// DescopeFlowViewController and preloads the flow in the background,
    /// so that when the user presses the Sign In button the flow is
    /// already fully ready
    case modalFlow

    /// A more complex example of authentication with flows that creates a
    /// DescopeFlowView instead of a controller, embeds the view into
    /// the view hierarchy, and shows it with a custom animation
    case inlineFlow

    /// Native UIKit login surface backed by the Descope SDK directly — supports
    /// password sign-in and SMS OTP without using a hosted webview flow
    case nativeLogin
}

/// Convenience functions for creating view controllers
extension AppInterface {
    static func createAuthScreen() -> UIViewController {
        let vc: UIViewController
        switch appInterface {
        case .menu: vc = AuthMenuController()
        case .passkeys: vc = PasskeysController()
        case .simpleFlow: vc = SimpleFlowController()
        case .modalFlow: vc = ModalFlowController()
        case .inlineFlow: vc = InlineFlowController()
        case .nativeLogin: vc = NativeLoginController()
        }
        let nav = UINavigationController(rootViewController: vc)
        applyNordAppearance(to: nav)
        return nav
    }

    static func createHomeScreen() -> UIViewController {
        let nav = UINavigationController(rootViewController: HomeViewController())
        applyNordAppearance(to: nav)
        return nav
    }

    private static func applyNordAppearance(to nav: UINavigationController) {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = NordColor.white
        appearance.shadowColor = NordColor.gray200
        appearance.titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 17, weight: .black),
            .foregroundColor: NordColor.black,
            .kern: 1.6,
        ]
        appearance.largeTitleTextAttributes = [
            .font: NordFont.serif(size: 32, weight: .bold),
            .foregroundColor: NordColor.black,
        ]
        nav.navigationBar.standardAppearance = appearance
        nav.navigationBar.scrollEdgeAppearance = appearance
        nav.navigationBar.tintColor = NordColor.black
        nav.view.tintColor = NordColor.black
    }
}

/// Convenience functions for transitioning between screens
extension AppInterface {
    static func transitionToAuthScreen(from: UIViewController) {
        transition(from: from, to: createAuthScreen())
    }

    static func transitionToHomeScreen(from: UIViewController) {
        transition(from: from, to: createHomeScreen())
    }

    private static func transition(from: UIViewController, to: UIViewController) {
        // transition from the window of the calling view controller
        let viewControllerWindow = from.viewIfLoaded?.window

        // alternatively, transition from the window of the navigation controller if the calling
        // view controller's is not currently visible
        let navigationControllerWindow = from.navigationController?.viewIfLoaded?.window

        // we must have a window to perform the transition on
        guard let window = viewControllerWindow ?? navigationControllerWindow else { preconditionFailure("Attempt to transition without a window") }

        UIView.transition(with: window, duration: 0.4, options: [.transitionCrossDissolve, .curveEaseOut]) {
            window.rootViewController = to
        }
    }
}

