
import UIKit
import DescopeKit

class HomeViewController: UIViewController {

    // Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        print("Showing home screen")
        view.backgroundColor = NordColor.white

        let wordmark = UILabel()
        wordmark.attributedText = .nordWordmark()
        navigationItem.titleView = wordmark

        let signOut = UIBarButtonItem(title: nil, style: .plain, target: self, action: #selector(didPressSignOut))
        signOut.setTitleTextAttributes([
            .font: NordFont.cta,
            .kern: 1.1,
            .foregroundColor: NordColor.black,
        ], for: .normal)
        signOut.title = "SIGN OUT"
        navigationItem.rightBarButtonItem = signOut
    }

    // Actions

    @objc func didPressSignOut() {
        print("Sign out pressed")
        clearSession()
        showAuth()
    }

    // Operations

    func clearSession() {
        // keep the session value before clearing it
        guard let session = Descope.sessionManager.session else { return }

        // clear the session from the manager, this effectively means the user
        // is logged out from the app
        Descope.sessionManager.clearSession()

        // we send a fire and forget asynchronous request to the Descope API to
        // revoke the session as it's not needed anymore
        Task {
            try? await Descope.auth.revokeSessions(.currentSession, refreshJwt: session.refreshJwt)
        }
    }

    // Views

    func showAuth() {
        AppInterface.transitionToAuthScreen(from: self)
    }
}
