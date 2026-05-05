
import UIKit

class AuthMenuController: UIViewController {

    @MainActor
    private struct Option {
        let title: String
        let subtitle: String
        let makeController: @MainActor () -> UIViewController
    }

    private let options: [Option] = [
        Option(title: "Passkeys", subtitle: "Native passkey sign-in", makeController: PasskeysController.init),
        Option(title: "Custom Code Sign In", subtitle: "Password or SMS OTP via SDK", makeController: NativeLoginController.init),
        Option(title: "Simple Flow", subtitle: "Push DescopeFlowViewController", makeController: SimpleFlowController.init),
        Option(title: "Modal Flow", subtitle: "Preloaded modal flow", makeController: ModalFlowController.init),
        Option(title: "Inline Flow", subtitle: "Embedded DescopeFlowView", makeController: InlineFlowController.init),
    ]

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = NordColor.white
        view.tintColor = NordColor.black

        let wordmark = UILabel()
        wordmark.attributedText = .nordWordmark()

        let eyebrow = UILabel()
        eyebrow.attributedText = NSAttributedString.nordCaps("Sign in to continue", font: NordFont.caption, tracking: 1.0, color: NordColor.gray600)

        let headline = UILabel()
        headline.text = "Welcome"
        headline.font = NordFont.serif(size: 36, weight: .bold)
        headline.textColor = NordColor.black

        let header = UIStackView(arrangedSubviews: [wordmark, headline, eyebrow])
        header.axis = .vertical
        header.alignment = .leading
        header.spacing = NordSpace.xs
        header.setCustomSpacing(NordSpace.lg, after: wordmark)

        let buttonStack = UIStackView()
        buttonStack.axis = .vertical
        buttonStack.spacing = NordSpace.sm
        for (index, option) in options.enumerated() {
            buttonStack.addArrangedSubview(makeRow(for: option, primary: index == 0))
        }

        let footer = UILabel()
        footer.attributedText = NSAttributedString.nordCaps("Powered by Descope", font: NordFont.micro, tracking: 1.0, color: NordColor.gray500)
        footer.textAlignment = .center

        let root = UIStackView(arrangedSubviews: [header, buttonStack, footer])
        root.axis = .vertical
        root.spacing = NordSpace.xl
        root.alignment = .fill
        root.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(root)

        NSLayoutConstraint.activate([
            root.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: NordSpace.xxl),
            root.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: NordSpace.md),
            root.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -NordSpace.md),
            root.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -NordSpace.lg),
        ])
    }

    private func makeRow(for option: Option, primary: Bool) -> UIView {
        let title = UILabel()
        title.attributedText = NSAttributedString.nordCaps(option.title, font: NordFont.cta, tracking: 1.1, color: primary ? NordColor.white : NordColor.black)

        let subtitle = UILabel()
        subtitle.text = option.subtitle
        subtitle.font = NordFont.bodySmall
        subtitle.textColor = primary ? NordColor.gray300 : NordColor.gray600

        let labels = UIStackView(arrangedSubviews: [title, subtitle])
        labels.axis = .vertical
        labels.spacing = 2
        labels.alignment = .leading

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = primary ? NordColor.white : NordColor.black
        chevron.contentMode = .scaleAspectFit
        chevron.setContentHuggingPriority(.required, for: .horizontal)

        let content = UIStackView(arrangedSubviews: [labels, chevron])
        content.axis = .horizontal
        content.alignment = .center
        content.spacing = NordSpace.sm
        content.isLayoutMarginsRelativeArrangement = true
        content.layoutMargins = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
        content.isUserInteractionEnabled = false

        let row = UIControl()
        row.backgroundColor = primary ? NordColor.black : NordColor.white
        row.layer.borderWidth = primary ? 0 : 2
        row.layer.borderColor = NordColor.black.cgColor
        row.translatesAutoresizingMaskIntoConstraints = false
        row.heightAnchor.constraint(greaterThanOrEqualToConstant: 56).isActive = true

        content.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: row.topAnchor),
            content.bottomAnchor.constraint(equalTo: row.bottomAnchor),
            content.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: row.trailingAnchor),
        ])

        let action = UIAction { [weak self] _ in
            self?.navigationController?.pushViewController(option.makeController(), animated: true)
        }
        row.addAction(action, for: .touchUpInside)
        row.addTarget(self, action: #selector(rowTouchDown(_:)), for: [.touchDown, .touchDragEnter])
        row.addTarget(self, action: #selector(rowTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit])
        return row
    }

    @objc private func rowTouchDown(_ sender: UIControl) {
        UIView.animate(withDuration: 0.15) { sender.transform = CGAffineTransform(scaleX: 0.98, y: 0.98) }
    }

    @objc private func rowTouchUp(_ sender: UIControl) {
        UIView.animate(withDuration: 0.15) { sender.transform = .identity }
    }
}
