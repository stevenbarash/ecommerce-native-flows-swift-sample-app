
import UIKit
import DescopeKit

class InlineFlowController: UIViewController {
    @IBOutlet var welcomeView: UIView!
    @IBOutlet var containerView: UIView!
    @IBOutlet var signinButton: UIButton!
    @IBOutlet var signinActivityIndicator: UIActivityIndicatorView!

    /// A reference to the DescopeFlowView for preloading the flow
    var flowView = DescopeFlowView()

    /// Marks whether the user pressed the sign in button and is waiting for the flow to be shown
    var shouldShowFlow = false

    // Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        applyNordEcommerceShell(
            headline: "NORDSTROM",
            subhead: "Your style awaits",
            body: "Sign in to access curated edits, designer drops, and your saved looks anywhere you shop.",
            cta: "Sign In",
            expandsContainerToFill: true,
            embedsBackButton: true
        )

        // add the DescopeFlowView into the controller's view hierarchy
        addFlowView()

        // collapse the hero panel when the keyboard rises so the input scrolls into the freed space
        registerKeyboardObservers()

        // preload after the push animation kicks off so WKWebView init doesn't stall the transition
        DispatchQueue.main.async { [weak self] in
            self?.startFlow()
        }
    }

    private var heroHiddenConstraint: NSLayoutConstraint?

    private func registerKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func handleKeyboardWillShow() {
        guard let hero = nordHeroPanel, !hero.isHidden else { return }
        if heroHiddenConstraint == nil {
            heroHiddenConstraint = hero.heightAnchor.constraint(equalToConstant: 0)
        }
        heroHiddenConstraint?.isActive = true
        UIView.animate(withDuration: 0.25) { [weak self] in
            hero.alpha = 0
            self?.view.layoutIfNeeded()
        }
    }

    @objc private func handleKeyboardWillHide() {
        guard let hero = nordHeroPanel else { return }
        heroHiddenConstraint?.isActive = false
        UIView.animate(withDuration: 0.25) { [weak self] in
            hero.alpha = 1
            self?.view.layoutIfNeeded()
        }
    }

    // Actions

    @IBAction func didPressSignIn() {
        print("Starting sign in with flow")

        switch flowView.state {
        case .initial, .failed:
            // the flow hasn't be started or needs to be restarted after failure
            shouldShowFlow = true
            startFlow()
            showLoadingStarted()
        case .started:
            // the flow has already been started, so just wait until it's ready
            shouldShowFlow = true
            showLoadingStarted()
        case .ready:
            // the flow is ready so show it immediately
            showFlowView()
        case .finished:
            break // shouldn't happen
        }
    }

    // Flow

    func startFlow() {
        let flow = DescopeFlow.nordSignIn(lockScroll: true)
        flow.hooks.append(.setupScrollView { scrollView in
            scrollView.isScrollEnabled = false
            scrollView.bounces = false
            scrollView.alwaysBounceVertical = false
            scrollView.showsVerticalScrollIndicator = false
            scrollView.contentInsetAdjustmentBehavior = .never
            scrollView.backgroundColor = .white
        })
        flowView.delegate = self
        flowView.start(flow: flow)
    }

    func addFlowView() {
        containerView.backgroundColor = .white
        flowView.backgroundColor = .white
        flowView.frame = containerView.bounds
        flowView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        containerView.addSubview(flowView)

        // walk every constraint involving containerView and kill the bottom-to-superview pin from the XIB
        let allConstraints = (containerView.superview?.constraints ?? []) + view.constraints
        for constraint in allConstraints where constraint.isActive {
            let firstIsContainer = constraint.firstItem === containerView
            let secondIsContainer = constraint.secondItem === containerView
            guard firstIsContainer || secondIsContainer else { continue }
            let containerSide = firstIsContainer ? constraint.firstAttribute : constraint.secondAttribute
            if containerSide == .bottom { constraint.isActive = false }
        }
        containerView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor).isActive = true
    }

    func resetFlowView() {
        // revert back to show the welcome screen
        showWelcomeView()

        // clear the delegate from any previous view controller and remove it from the view
        flowView.delegate = nil
        flowView.removeFromSuperview()

        // override the flow view with a new one so if the user taps the Sign In button
        // again they'll get a new flow
        flowView = DescopeFlowView()
        addFlowView()
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

    // Animations

    func showLoadingStarted() {
        UIView.animate(withDuration: 0.2) { [self] in
            signinButton.isUserInteractionEnabled = false
            signinButton.setTitle("", for: .normal)
            signinActivityIndicator.alpha = 1
        }
    }

    func showLoadingFinished() {
        UIView.animate(withDuration: 0.2) { [self] in
            signinButton.isUserInteractionEnabled = true
            signinButton.setTitle("Sign In", for: .normal)
            signinActivityIndicator.alpha = 0
        }
    }

    func showFlowView() {
        // only animate the flow view in if it's still hidden
        guard containerView.isHidden else { return }
        containerView.isHidden = false

        // start the animation with a scaled down and transparent container for the flow view
        containerView.alpha = 0
        containerView.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)

        // fade out and scale down the welcome view
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut], animations: { [self] in
            welcomeView.alpha = 0
            welcomeView.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        }, completion: nil)

        // fade in and scale up the container for the flow view
        UIView.animate(withDuration: 0.3, delay: 0.1, options: [.curveEaseOut], animations: { [self] in
            containerView.alpha = 1
            containerView.transform = .identity
        }, completion: nil)
    }

    func showWelcomeView() {
        containerView.isHidden = true
        welcomeView.alpha = 1
        welcomeView.transform = .identity
    }
}

extension InlineFlowController: DescopeFlowViewDelegate {
    func flowViewDidUpdateState(_ flowView: DescopeFlowView, to state: DescopeFlowState, from previous: DescopeFlowState) {
        print("Flow state changed to \(state) from \(previous)")
    }
    
    func flowViewDidBecomeReady(_ flowView: DescopeFlowView) {
        // if the shouldShowFlow flag is true that means the user pressed the Sign In button
        // while the flow was still not ready, in which case we'll show it now
        if shouldShowFlow {
            shouldShowFlow = false
            showLoadingFinished()
            showFlowView()
        }
    }
    
    func flowViewDidInterceptNavigation(_ flowView: DescopeFlowView, url: URL, external: Bool) {
        // if there are web links in our flow and the user taps one of them we simply open
        // it in the user's default browser app
        UIApplication.shared.open(url)
    }

    func flowViewDidFail(_ flowView: DescopeFlowView, error: DescopeError) {
        // it's important to pay attention that because we're preloading the flow, this delegate
        // function might be called BEFORE the DescopeFlowView is actually shown, most likely due
        // to a network error, and the implementation should be careful to work properly in every
        // case. In this example resetFlowView will just hide the flow view and show the welcome
        // view again which will do nothing if the flow view hasn't actually been shown yet.
        print("Authentication failed: \(error)")
        resetFlowView()

        // since the error might have happened before the flow was ready to be presented, we need
        // to reset the loading indicator to ensure the user can press the Sign In button again
        showLoadingFinished()

        // errors will usually be .networkError or .flowFailed
        showError(error)
    }
    
    func flowViewDidFinish(_ flowView: DescopeFlowView, response: AuthenticationResponse) {
        let session = DescopeSession(from: response)
        Descope.sessionManager.manageSession(session)
        print("Authentication finished")
        showHome()
    }
}
