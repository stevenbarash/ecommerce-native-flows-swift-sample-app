
import UIKit
import DescopeKit

enum NordColor {
    static let black    = UIColor(hex: 0x000000)
    static let white    = UIColor(hex: 0xFFFFFF)
    static let gray50   = UIColor(hex: 0xF9F9F9)
    static let gray100  = UIColor(hex: 0xF2F2F2)
    static let gray200  = UIColor(hex: 0xE5E5E5)
    static let gray300  = UIColor(hex: 0xD4D4D4)
    static let gray400  = UIColor(hex: 0xA3A3A3)
    static let gray500  = UIColor(hex: 0x737373)
    static let gray600  = UIColor(hex: 0x525252)
    static let gray700  = UIColor(hex: 0x404040)
    static let red      = UIColor(hex: 0xCC0000)
    static let redDark  = UIColor(hex: 0xA50000)
    static let link     = UIColor(hex: 0x0F6CBD)
}

enum NordSpace {
    static let xxs: CGFloat = 4
    static let xs:  CGFloat = 8
    static let sm:  CGFloat = 12
    static let md:  CGFloat = 16
    static let lg:  CGFloat = 24
    static let xl:  CGFloat = 36
    static let xxl: CGFloat = 56
}

enum NordFont {
    static let display      = UIFont.systemFont(ofSize: 56, weight: .bold)
    static let displaySmall = UIFont.systemFont(ofSize: 36, weight: .bold)
    static let h1           = UIFont.systemFont(ofSize: 28, weight: .black)
    static let h2           = UIFont.systemFont(ofSize: 20, weight: .bold)
    static let h3           = UIFont.systemFont(ofSize: 16, weight: .bold)
    static let body         = UIFont.systemFont(ofSize: 15, weight: .regular)
    static let bodySmall    = UIFont.systemFont(ofSize: 13, weight: .regular)
    static let caption      = UIFont.systemFont(ofSize: 12, weight: .regular)
    static let micro        = UIFont.systemFont(ofSize: 11, weight: .regular)
    static let cta          = UIFont.systemFont(ofSize: 13, weight: .bold)
    static let badge        = UIFont.systemFont(ofSize: 10, weight: .bold)

    static func serif(size: CGFloat, weight: UIFont.Weight = .bold) -> UIFont {
        let descriptor = UIFontDescriptor
            .preferredFontDescriptor(withTextStyle: .body)
            .withDesign(.serif)?
            .addingAttributes([.traits: [UIFontDescriptor.TraitKey.weight: weight]])
        guard let descriptor else { return UIFont.systemFont(ofSize: size, weight: weight) }
        return UIFont(descriptor: descriptor, size: size)
    }
}

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1.0) {
        let r = CGFloat((hex >> 16) & 0xFF) / 255
        let g = CGFloat((hex >> 8)  & 0xFF) / 255
        let b = CGFloat(hex & 0xFF) / 255
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
}

extension NSAttributedString {
    /// Uppercase + letter-spaced label, the Nordstrom signature treatment.
    static func nordCaps(_ text: String, font: UIFont = NordFont.cta, tracking: CGFloat = 1.1, color: UIColor = NordColor.white) -> NSAttributedString {
        NSAttributedString(string: text.uppercased(), attributes: [
            .font: font,
            .foregroundColor: color,
            .kern: tracking,
        ])
    }

    /// The signature `NORDSTROM` wordmark — black 22pt heavy, kerned 2.6.
    static func nordWordmark(_ text: String = "NORDSTROM") -> NSAttributedString {
        NSAttributedString(string: text, attributes: [
            .font: UIFont.systemFont(ofSize: 22, weight: .black),
            .foregroundColor: NordColor.black,
            .kern: 2.6,
        ])
    }
}

extension DescopeFlow {
    /// Builds a Descope hosted-flow request with the Nord background + shadow overrides applied.
    /// Pass `lockScroll: true` for inline embedding (kills page scroll + JS scrollIntoView).
    static func nordSignIn(flowId: String = "sign-up-or-in", lockScroll: Bool = false) -> DescopeFlow {
        let baseURL = Descope.config.baseURL ?? "https://api.descope.com"
        let url = "\(baseURL)/login/\(Descope.config.projectId)?mobile=true&flow=\(flowId)&bg=%23ffffff"
        let flow = DescopeFlow(url: url)

        var css = """
            html, body, #root, .descope-container, [class*='container'], [class*='Container'] {
                background-color: #ffffff !important;
                background: #ffffff !important;
                box-shadow: none !important;
                filter: none !important;
            }
            html, body { margin: 0 !important; padding: 0 !important; }
            * { box-shadow: none !important; }
        """
        if lockScroll {
            css += "\nhtml, body { overflow: hidden !important; height: 100% !important; position: fixed !important; width: 100% !important; }"
        }

        var hooks: [DescopeFlowHook] = [.addStyles(css: css)]
        if lockScroll {
            hooks.append(.runJavaScript(on: .ready, code: """
                Element.prototype.scrollIntoView = function() {};
                window.scrollTo = function() {};
                document.documentElement.scrollTop = 0;
                document.body.scrollTop = 0;
            """))
        }
        flow.hooks = hooks
        return flow
    }
}

extension UIButton.Configuration {
    /// Black sharp-edge filled button with uppercase tracked label — the Nord primary CTA.
    static func nordPrimary(title: String) -> UIButton.Configuration {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = NordColor.black
        config.baseForegroundColor = NordColor.white
        config.cornerStyle = .fixed
        config.background.cornerRadius = 0
        config.attributedTitle = AttributedString(NSAttributedString.nordCaps(title, font: NordFont.cta, tracking: 1.1, color: NordColor.white))
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)
        return config
    }
}

/// Tag used to locate the Nord hero panel after `applyNordEcommerceShell` installs it.
let NordHeroPanelTag = 9_001

extension UIViewController {
    /// The Nord hero panel installed by `applyNordEcommerceShell`, if any.
    @MainActor
    var nordHeroPanel: UIView? {
        view.subviews.first { $0.tag == NordHeroPanelTag }
    }

    /// Strip the legacy ski-themed XIB visuals and apply Nordstrom ecommerce treatment.
    /// Looks for the largest UILabel as a headline, the next-largest as body copy, and the first
    /// UIButton as the primary CTA. Replaces their styling and text content.
    @MainActor
    func applyNordEcommerceShell(headline: String, subhead: String, body: String, cta: String, expandsContainerToFill: Bool = false, embedsBackButton: Bool = false) {
        view.backgroundColor = NordColor.white
        view.tintColor = NordColor.black

        var imageViews: [UIImageView] = []
        var labels: [UILabel] = []
        var buttons: [UIButton] = []
        collectNordTargets(in: view, imageViews: &imageViews, labels: &labels, buttons: &buttons)

        var hiddenImageView: UIImageView?
        for imageView in imageViews where imageView.image != nil {
            imageView.image = nil
            imageView.isHidden = true
            hiddenImageView = imageView
        }
        if hiddenImageView != nil {
            installNordHeroPanel(expandsContainerToFill: expandsContainerToFill, embedsBackButton: embedsBackButton)
        }

        let sortedLabels = labels.sorted { $0.font.pointSize > $1.font.pointSize }
        if let titleLabel = sortedLabels.first {
            titleLabel.attributedText = NSAttributedString(string: headline, attributes: [
                .font: UIFont.systemFont(ofSize: 22, weight: .black),
                .foregroundColor: NordColor.black,
                .kern: 2.6,
            ])
        }
        if sortedLabels.count > 1 {
            let bodyLabel = sortedLabels[1]
            let attributed = NSMutableAttributedString()
            attributed.append(NSAttributedString.nordCaps(subhead, font: NordFont.caption, tracking: 1.0, color: NordColor.gray600))
            attributed.append(NSAttributedString(string: "\n\n", attributes: [.font: NordFont.body]))
            attributed.append(NSAttributedString(string: body, attributes: [
                .font: NordFont.body,
                .foregroundColor: NordColor.black,
            ]))
            bodyLabel.attributedText = attributed
            bodyLabel.alpha = 1
            bodyLabel.numberOfLines = 0
        }

        if let primaryButton = buttons.first {
            primaryButton.configuration = .nordPrimary(title: cta)
            primaryButton.tintColor = NordColor.black
        }
    }

    private func installNordHeroPanel(expandsContainerToFill: Bool, embedsBackButton: Bool) {
        let bottomContainer = view.subviews.first { !($0 is UIImageView) && !$0.isHidden && $0.frame.minY > view.bounds.midY * 0.5 }

        let canPop = (navigationController?.viewControllers.count ?? 0) > 1
        if embedsBackButton {
            // collapse the system nav bar — the hero panel hosts its own back affordance
            navigationController?.setNavigationBarHidden(true, animated: false)
        }

        var headerRow: UIView?
        if embedsBackButton, canPop {
            let backButton = UIButton(type: .system)
            var config = UIButton.Configuration.plain()
            config.image = UIImage(systemName: "chevron.left")
            config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
            config.baseForegroundColor = NordColor.black
            config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 12)
            backButton.configuration = config
            backButton.contentHorizontalAlignment = .leading
            backButton.addAction(UIAction { [weak self] _ in self?.navigationController?.popViewController(animated: true) }, for: .touchUpInside)

            let row = UIStackView(arrangedSubviews: [backButton, UIView()])
            row.axis = .horizontal
            row.alignment = .center
            headerRow = row
        }

        let editorial = UILabel()
        editorial.numberOfLines = 0
        editorial.attributedText = NSAttributedString(string: "Dressed for everything.", attributes: [
            .font: NordFont.serif(size: 34, weight: .bold),
            .foregroundColor: NordColor.black,
            .kern: -0.5,
        ])

        let eyebrow = UILabel()
        eyebrow.attributedText = NSAttributedString.nordCaps("New season · Now in", font: NordFont.caption, tracking: 1.2, color: NordColor.gray600)

        let benefits = UIStackView(arrangedSubviews: [
            makeBenefitChip(icon: "shippingbox", text: "Free Shipping"),
            makeBenefitChip(icon: "arrow.uturn.backward", text: "Free Returns"),
            makeBenefitChip(icon: "star.circle", text: "Nordy Club"),
        ])
        benefits.axis = .horizontal
        benefits.distribution = .fillEqually
        benefits.spacing = NordSpace.xs

        var arranged: [UIView] = []
        if let headerRow { arranged.append(headerRow) }
        arranged.append(contentsOf: [eyebrow, editorial, benefits])

        let stack = UIStackView(arrangedSubviews: arranged)
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = NordSpace.md
        if headerRow != nil {
            stack.setCustomSpacing(NordSpace.xs, after: arranged[0])
        }
        stack.setCustomSpacing(NordSpace.xxs, after: eyebrow)
        stack.setCustomSpacing(NordSpace.lg, after: editorial)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.tag = NordHeroPanelTag
        view.addSubview(stack)

        let topAnchor = stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: NordSpace.md)
        let leading = stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: NordSpace.lg)
        let trailing = stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -NordSpace.lg)
        var constraints: [NSLayoutConstraint] = [topAnchor, leading, trailing]
        if let bottomContainer, expandsContainerToFill {
            // remove the XIB's 50%-height constraint on the container so it can sit right under the hero
            for constraint in view.constraints where constraint.firstAttribute == .height && (constraint.firstItem === bottomContainer || constraint.secondItem === bottomContainer) {
                constraint.isActive = false
            }
            constraints.append(bottomContainer.topAnchor.constraint(equalTo: stack.bottomAnchor, constant: NordSpace.md))
        } else if let bottomContainer {
            // keep the XIB's 50%-height behavior — container hugs its intrinsic-sized content
            constraints.append(stack.bottomAnchor.constraint(lessThanOrEqualTo: bottomContainer.topAnchor, constant: -NordSpace.sm))
        }
        NSLayoutConstraint.activate(constraints)
    }

    private func makeBenefitChip(icon: String, text: String) -> UIView {
        let symbol = UIImageView(image: UIImage(systemName: icon))
        symbol.tintColor = NordColor.black
        symbol.contentMode = .scaleAspectFit
        symbol.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        symbol.heightAnchor.constraint(equalToConstant: 24).isActive = true

        let label = UILabel()
        label.attributedText = NSAttributedString.nordCaps(text, font: NordFont.micro, tracking: 0.8, color: NordColor.gray700)
        label.textAlignment = .center
        label.numberOfLines = 2

        let chip = UIStackView(arrangedSubviews: [symbol, label])
        chip.axis = .vertical
        chip.alignment = .center
        chip.spacing = NordSpace.xxs
        return chip
    }

    private func collectNordTargets(in view: UIView, imageViews: inout [UIImageView], labels: inout [UILabel], buttons: inout [UIButton]) {
        for subview in view.subviews {
            if let imageView = subview as? UIImageView { imageViews.append(imageView) }
            else if let button = subview as? UIButton { buttons.append(button) }
            else if let label = subview as? UILabel { labels.append(label) }
            collectNordTargets(in: subview, imageViews: &imageViews, labels: &labels, buttons: &buttons)
        }
    }
}
