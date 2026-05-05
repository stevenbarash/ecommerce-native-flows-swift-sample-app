
import UIKit
import DescopeKit

/// Native sign-in surface backed directly by the Descope SDK — no hosted webview flow.
/// Supports password sign-in and SMS OTP.
class NativeLoginController: UIViewController {

    private enum Mode: Int { case signIn, signUp, sms }

    private let modeSelector = UISegmentedControl(items: ["Sign In", "Sign Up", "SMS Code"])

    private var currentMode: Mode {
        Mode(rawValue: modeSelector.selectedSegmentIndex) ?? .signIn
    }
    private let emailField = UITextField()
    private let passwordField = UITextField()
    private let phoneField = UITextField()
    private let codeField = UITextField()

    private let primaryButton = UIButton(configuration: .filled())
    private let secondaryLabel = UILabel()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)

    private var passwordSection: UIStackView!
    private var smsRequestSection: UIStackView!
    private var smsVerifySection: UIStackView!

    private var pendingPhoneNumber: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = NordColor.white
        title = nil

        let wordmark = UILabel()
        wordmark.attributedText = .nordWordmark()

        let eyebrow = UILabel()
        eyebrow.attributedText = NSAttributedString.nordCaps("Native sign in", font: NordFont.caption, tracking: 1.0, color: NordColor.gray600)

        let headline = UILabel()
        headline.text = "Sign in to your account."
        headline.font = NordFont.serif(size: 30, weight: .bold)
        headline.textColor = NordColor.black
        headline.numberOfLines = 0

        modeSelector.selectedSegmentIndex = 0
        modeSelector.addAction(UIAction { [weak self] _ in self?.modeChanged() }, for: .valueChanged)

        passwordSection = makePasswordSection()
        smsRequestSection = makeSMSRequestSection()
        smsVerifySection = makeSMSVerifySection()
        smsRequestSection.isHidden = true
        smsVerifySection.isHidden = true

        configurePrimaryButton(title: "Sign In")
        primaryButton.addAction(UIAction { [weak self] _ in self?.didTapPrimary() }, for: .touchUpInside)

        secondaryLabel.font = NordFont.caption
        secondaryLabel.textColor = NordColor.red
        secondaryLabel.numberOfLines = 0
        secondaryLabel.textAlignment = .center

        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.color = NordColor.white

        let root = UIStackView(arrangedSubviews: [
            wordmark,
            eyebrow,
            headline,
            modeSelector,
            passwordSection,
            smsRequestSection,
            smsVerifySection,
            primaryButton,
            secondaryLabel,
        ])
        root.axis = .vertical
        root.spacing = NordSpace.md
        root.setCustomSpacing(NordSpace.lg, after: wordmark)
        root.setCustomSpacing(NordSpace.xxs, after: eyebrow)
        root.setCustomSpacing(NordSpace.lg, after: headline)
        root.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(root)

        primaryButton.translatesAutoresizingMaskIntoConstraints = false
        primaryButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        primaryButton.addSubview(loadingIndicator)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: primaryButton.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: primaryButton.centerYAnchor),
        ])

        NSLayoutConstraint.activate([
            root.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: NordSpace.lg),
            root.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: NordSpace.md),
            root.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -NordSpace.md),
        ])

        modeChanged()
    }

    private func makePasswordSection() -> UIStackView {
        styleField(emailField, placeholder: "Email", keyboard: .emailAddress, content: .username)
        styleField(passwordField, placeholder: "Password", isSecure: true, content: .password)
        let stack = UIStackView(arrangedSubviews: [emailField, passwordField])
        stack.axis = .vertical
        stack.spacing = NordSpace.sm
        return stack
    }

    private func makeSMSRequestSection() -> UIStackView {
        styleField(phoneField, placeholder: "Phone (e.g. +12025550100)", keyboard: .phonePad, content: .telephoneNumber)
        let stack = UIStackView(arrangedSubviews: [phoneField])
        stack.axis = .vertical
        stack.spacing = NordSpace.sm
        return stack
    }

    private func makeSMSVerifySection() -> UIStackView {
        styleField(codeField, placeholder: "6-digit code", keyboard: .numberPad, content: .oneTimeCode)
        let stack = UIStackView(arrangedSubviews: [codeField])
        stack.axis = .vertical
        stack.spacing = NordSpace.sm
        return stack
    }

    private func styleField(_ field: UITextField, placeholder: String, keyboard: UIKeyboardType = .default, isSecure: Bool = false, content: UITextContentType? = nil) {
        field.placeholder = placeholder
        field.font = NordFont.body
        field.textColor = NordColor.black
        field.borderStyle = .none
        field.keyboardType = keyboard
        field.isSecureTextEntry = isSecure
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        if let content { field.textContentType = content }

        let bottomBorder = UIView()
        bottomBorder.backgroundColor = NordColor.gray300
        bottomBorder.translatesAutoresizingMaskIntoConstraints = false
        field.addSubview(bottomBorder)
        NSLayoutConstraint.activate([
            field.heightAnchor.constraint(equalToConstant: 44),
            bottomBorder.leadingAnchor.constraint(equalTo: field.leadingAnchor),
            bottomBorder.trailingAnchor.constraint(equalTo: field.trailingAnchor),
            bottomBorder.bottomAnchor.constraint(equalTo: field.bottomAnchor),
            bottomBorder.heightAnchor.constraint(equalToConstant: 1),
        ])
    }

    private func configurePrimaryButton(title: String) {
        primaryButton.configuration = .nordPrimary(title: title)
    }

    private func modeChanged() {
        secondaryLabel.text = nil
        let mode = currentMode
        switch mode {
        case .signIn:
            passwordSection.isHidden = false
            smsRequestSection.isHidden = true
            smsVerifySection.isHidden = true
            passwordField.textContentType = .password
            configurePrimaryButton(title: "Sign In")
        case .signUp:
            passwordSection.isHidden = false
            smsRequestSection.isHidden = true
            smsVerifySection.isHidden = true
            passwordField.textContentType = .newPassword
            configurePrimaryButton(title: "Create Account")
        case .sms:
            passwordSection.isHidden = true
            if pendingPhoneNumber == nil {
                smsRequestSection.isHidden = false
                smsVerifySection.isHidden = true
                configurePrimaryButton(title: "Send Code")
            } else {
                smsRequestSection.isHidden = true
                smsVerifySection.isHidden = false
                configurePrimaryButton(title: "Verify")
            }
        }
    }

    private func didTapPrimary() {
        secondaryLabel.text = nil
        let mode = currentMode
        switch mode {
        case .signIn, .signUp:
            let email = emailField.text?.trimmingCharacters(in: .whitespaces) ?? ""
            let password = passwordField.text ?? ""
            guard !email.isEmpty, !password.isEmpty else {
                secondaryLabel.text = "Enter email and password."
                return
            }
            Task { await performPassword(email: email, password: password, mode: mode) }
        case .sms:
            if let phone = pendingPhoneNumber {
                let code = codeField.text?.trimmingCharacters(in: .whitespaces) ?? ""
                guard !code.isEmpty else {
                    secondaryLabel.text = "Enter the code sent to your phone."
                    return
                }
                Task { await performSMSVerify(phone: phone, code: code) }
            } else {
                let phone = phoneField.text?.trimmingCharacters(in: .whitespaces) ?? ""
                guard !phone.isEmpty else {
                    secondaryLabel.text = "Enter your phone number."
                    return
                }
                Task { await performSMSRequest(phone: phone) }
            }
        }
    }

    private func setLoading(_ loading: Bool) {
        primaryButton.isEnabled = !loading
        modeSelector.isEnabled = !loading
        if loading {
            primaryButton.configuration?.attributedTitle = nil
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
        }
    }

    private func performPassword(email: String, password: String, mode: Mode) async {
        setLoading(true)
        defer { setLoading(false); modeChanged() }
        do {
            let authResponse: AuthenticationResponse
            switch mode {
            case .signIn:
                authResponse = try await Descope.password.signIn(loginId: email, password: password)
            case .signUp:
                authResponse = try await Descope.password.signUp(loginId: email, password: password, details: nil)
            case .sms:
                return
            }
            completeAuthentication(authResponse)
        } catch {
            secondaryLabel.textColor = NordColor.red
            secondaryLabel.text = friendlyMessage(for: error, mode: mode)
        }
    }

    private func performSMSRequest(phone: String) async {
        setLoading(true)
        defer { setLoading(false); modeChanged() }
        do {
            _ = try await Descope.otp.signUpOrIn(with: .sms, loginId: phone, options: [])
            pendingPhoneNumber = phone
            secondaryLabel.textColor = NordColor.gray600
            secondaryLabel.text = "Code sent. Check your messages."
        } catch {
            secondaryLabel.textColor = NordColor.red
            secondaryLabel.text = friendlyMessage(for: error, mode: .sms)
        }
    }

    private func performSMSVerify(phone: String, code: String) async {
        setLoading(true)
        defer { setLoading(false); modeChanged() }
        do {
            let authResponse = try await Descope.otp.verify(with: .sms, loginId: phone, code: code)
            completeAuthentication(authResponse)
        } catch {
            // wrong code shouldn't reset the verify flow — let user retry
            if let descopeError = error as? DescopeError, descopeError.code == DescopeError.wrongOTPCode.code {
                secondaryLabel.textColor = NordColor.red
                secondaryLabel.text = "Incorrect code. Try again."
            } else {
                secondaryLabel.textColor = NordColor.red
                secondaryLabel.text = friendlyMessage(for: error, mode: .sms)
            }
        }
    }

    private func completeAuthentication(_ authResponse: AuthenticationResponse) {
        let session = DescopeSession(from: authResponse)
        Descope.sessionManager.manageSession(session)
        AppInterface.transitionToHomeScreen(from: self)
    }

    private func friendlyMessage(for error: Error, mode: Mode) -> String {
        guard let descopeError = error as? DescopeError else {
            return error.localizedDescription
        }
        // common Descope user-facing codes
        switch descopeError.code {
        case "E062102", "E062108":
            return mode == .signIn ? "No account found. Try Sign Up instead." : "Could not create account. \(descopeError.message)"
        case "E062801", "E062802", "E062803":
            return "Incorrect email or password."
        case "E063003", "E063004":
            return "Account already exists. Try Sign In instead."
        case DescopeError.tooManyOTPAttempts.code:
            return "Too many attempts. Wait a moment and try again."
        case DescopeError.networkError.code:
            return "Network error. Check your connection."
        default:
            let message = descopeError.message ?? ""
            return message.isEmpty ? descopeError.localizedDescription : message
        }
    }
}
