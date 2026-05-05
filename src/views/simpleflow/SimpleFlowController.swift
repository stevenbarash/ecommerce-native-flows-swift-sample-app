
import UIKit
import DescopeKit

class SimpleFlowController: UIViewController {

    /// Preloaded flow controller; webview init runs off the tap path so push feels instant.
    private var flowViewController = DescopeFlowViewController()

    override func viewDidLoad() {
        super.viewDidLoad()
        applyNordEcommerceShell(
            headline: "NORDSTROM",
            subhead: "Member exclusive",
            body: "Sign in to save your bag, view order history, and unlock free shipping on every order.",
            cta: "Sign In to Shop"
        )

        // preload after the push animation kicks off so WKWebView init doesn't stall the transition
        DispatchQueue.main.async { [weak self] in
            self?.preloadFlow()
        }
    }

    private func preloadFlow() {
        let flow = DescopeFlow.nordSignIn()
        flow.hooks.append(.setupScrollView { scrollView in
            scrollView.backgroundColor = .white
            scrollView.contentInsetAdjustmentBehavior = .never
        })
        flowViewController.view.backgroundColor = .white
        flowViewController.delegate = self
        flowViewController.start(flow: flow)
    }

    /// This action is called when the user taps the Sign In button
    @IBAction func didPressSignIn() {
        print("Starting sign in with flow")
        showFlow()
    }

    /// Pushes the preloaded DescopeFlowViewController onto the navigation stack
    func showFlow() {
        navigationController?.pushViewController(flowViewController, animated: true)
    }

    // Results

    func showError(_ error: Error) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }

    func showHome() {
        AppInterface.transitionToHomeScreen(from: self)
    }
}

extension SimpleFlowController: DescopeFlowViewControllerDelegate {
    func flowViewControllerDidUpdateState(_ controller: DescopeFlowViewController, to state: DescopeFlowState, from previous: DescopeFlowState) {
        print("Flow state changed to \(state) from \(previous)")
    }
    
    func flowViewControllerDidBecomeReady(_ controller: DescopeFlowViewController) {
        // the flow is preloaded in the background; the user navigates to it on
        // tap regardless of ready state, so no ready-event handling is needed
    }
    
    func flowViewControllerShouldShowURL(_ controller: DescopeFlowViewController, url: URL, external: Bool) -> Bool {
        // we return true so that the DescopeFlowViewController does its builtin behavior
        // of opening the URL in the user's default browser app
        return true
    }
    
    func flowViewControllerDidCancel(_ controller: DescopeFlowViewController) {
        // in this example the cancel button isn't shown and this function can't be called,
        // because the DescopeFlowViewController isn't at the root of its navigation controller
        // stack, and the user gets the default Back button to leave the flow screen
    }
    
    func flowViewControllerDidFail(_ controller: DescopeFlowViewController, error: DescopeError) {
        print("Authentication failed: \(error)")
        
        // errors will usually be DescopeError.networkError or DescopeError.flowFailed
        showError(error)
    }
    
    func flowViewControllerDidFinish(_ controller: DescopeFlowViewController, response: AuthenticationResponse) {
        print("Authentication finished")

        // authentication succeeded so we can create a new DescopeSession and set it on the
        // session manager, which is effectively what we consider as the user being signed in
        // to the application
        let session = DescopeSession(from: response)
        Descope.sessionManager.manageSession(session)
        
        // finally, transition the user to the home screen
        showHome()
    }
}
