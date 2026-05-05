# Nordstrom iOS / SwiftUI Style Guide

Hand this file to an agentic coding tool to design a SwiftUI app that matches the Nordstrom storefront aesthetic shown in this repo's web demo. Tokens distilled from `src/index.css` and component CSS modules. Target: iOS 17+, SwiftUI, no external dependencies.

---

## 1. Brand voice

- **Editorial luxury, not flashy.** Heavy use of black, white, and neutral grays. Restraint over ornament.
- **Type-driven hierarchy.** A tight serif for emotional/headline moments, a humanist sans for everything else.
- **Dense product grids, generous whitespace around them.** Imagery is the hero; chrome recedes.
- **Sharp edges by default.** Most surfaces and cards have **no corner radius**. Pills (radius 999) only on search inputs and capsule chips.
- **No drop shadows** as a stylistic crutch. Use 1px hairline borders in `gray-200`/`gray-300` to separate.
- **Uppercase, letter-spaced micro-copy** for buttons, eyebrows, badges, and nav. This is the single most identifying mark of the brand.

---

## 2. Color tokens

Define once in an `Asset Catalog` color set or as static `Color` extensions. Provide light + dark variants where noted; the design is light-first — dark mode should feel like a true neutral inversion, not Nordy Rack red.

```swift
extension Color {
    // Core
    static let nordBlack    = Color(hex: 0x000000)
    static let nordWhite    = Color(hex: 0xFFFFFF)

    // Neutral ramp (use these instead of opacities on black)
    static let nordGray50   = Color(hex: 0xF9F9F9) // page tints
    static let nordGray100  = Color(hex: 0xF2F2F2) // image placeholder, soft fills
    static let nordGray200  = Color(hex: 0xE5E5E5) // hairline dividers
    static let nordGray300  = Color(hex: 0xD4D4D4) // input borders, swatch outlines
    static let nordGray400  = Color(hex: 0xA3A3A3) // placeholder text
    static let nordGray500  = Color(hex: 0x737373) // tertiary copy, icon ghosts
    static let nordGray600  = Color(hex: 0x525252) // secondary copy
    static let nordGray700  = Color(hex: 0x404040) // hover/pressed black

    // Accent
    static let nordRed      = Color(hex: 0xCC0000) // sale, Rack brand, error
    static let nordRedDark  = Color(hex: 0xA50000)
    static let nordLink     = Color(hex: 0x0F6CBD) // gift / informational links
}
```

Helper for hex:

```swift
extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8)  & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
```

### Usage rules
- **Backgrounds:** `nordWhite` everywhere. Section tints use `nordGray50` or `nordGray100`. Never tint a card.
- **Body text:** `nordBlack`. Secondary `nordGray600`. Tertiary / metadata `nordGray500`. Disabled `nordGray400`.
- **Dividers:** 1px `nordGray200` (sections) or `nordGray300` (form inputs).
- **Sale price:** `nordRed`, bold. Original price beside it: `nordGray500` with strikethrough.
- **Rack sub-brand:** swap logo + sale link to `nordRed`. Don't bleed Rack red into other surfaces.

---

## 3. Typography

iOS doesn't ship with Lato or Playfair Display. Bundle them as custom fonts, or use the SF system fallback. Both options below.

### Font families

| Role     | Web token     | iOS bundled       | iOS system fallback        |
|----------|---------------|-------------------|----------------------------|
| Sans     | `Lato`        | `Lato-Regular/700/900` | `.system(design: .default)` |
| Serif    | `Playfair Display` | `PlayfairDisplay-Regular/700` | `.system(design: .serif)` |
| Mono     | `SF Mono`     | (system)          | `.system(design: .monospaced)` |

Add Lato + Playfair Display to `Info.plist` under `UIAppFonts`. If shipping system-only, use `.serif` design for headlines — it's the closest tonal match.

### Type scale

The web ranges from 9px micro-copy to 140px display. Keep a tight ramp on iOS — fewer steps, larger minimum (11pt) for legibility.

```swift
enum NordType {
    // Display (serif, editorial moments — hero, category splash)
    static let display       = Font.custom("PlayfairDisplay-Regular", size: 56).weight(.bold) // hero
    static let displaySmall  = Font.custom("PlayfairDisplay-Regular", size: 36).weight(.bold)

    // Headlines (sans, all-caps eyebrows or section titles)
    static let h1            = Font.custom("Lato-Black",    size: 28) // page title
    static let h2            = Font.custom("Lato-Bold",     size: 20) // section header
    static let h3            = Font.custom("Lato-Bold",     size: 16) // card title

    // Body
    static let body          = Font.custom("Lato-Regular",  size: 15)
    static let bodySmall     = Font.custom("Lato-Regular",  size: 13)
    static let caption       = Font.custom("Lato-Regular",  size: 12)
    static let micro         = Font.custom("Lato-Regular",  size: 11) // utility/site-bar

    // Action / CTA — always paired with .uppercase() and tracking
    static let cta           = Font.custom("Lato-Bold",     size: 13)
    static let badge         = Font.custom("Lato-Bold",     size: 10)
}
```

If using system-only:

```swift
static let h1 = Font.system(size: 28, weight: .black, design: .default)
static let display = Font.system(size: 56, weight: .bold, design: .serif)
```

### Letter spacing (tracking)

Tracking is the brand's tell. Apply via `.tracking(_:)`:

| Use                          | Tracking      |
|------------------------------|---------------|
| Body, paragraphs             | `0` (normal)  |
| Eyebrow / nav (small caps)   | `1.0` (≈0.08em at 13pt) |
| CTA button label             | `1.0` to `1.2` |
| Badge (10pt uppercase)       | `0.5`         |
| Display headline (large serif) | `-0.5` (negative tightens) |

```swift
Text("ADD TO BAG")
    .font(NordType.cta)
    .tracking(1.1)
    .textCase(.uppercase)
```

### Line height

`lineSpacing(2)` for body, `lineSpacing(0)` for CTAs and uppercase labels. Display headlines: tight — use `.lineSpacing(-2)` or set `Text.lineLimit` and rely on default.

---

## 4. Spacing & layout

The web uses arbitrary px gaps (8, 10, 12, 16, 20, 24, 28, 36). On iOS quantize to a 4-pt grid:

```swift
enum NordSpace {
    static let xxs: CGFloat = 4
    static let xs:  CGFloat = 8
    static let sm:  CGFloat = 12
    static let md:  CGFloat = 16
    static let lg:  CGFloat = 24
    static let xl:  CGFloat = 36
    static let xxl: CGFloat = 56
}
```

- **Screen edge padding:** `NordSpace.md` (16) on phone, `NordSpace.lg` (24) on iPad.
- **Card → card gap in grid:** `NordSpace.sm` horizontal, `NordSpace.lg` vertical.
- **Section vertical rhythm:** `NordSpace.xl` between major sections, `NordSpace.lg` between subsections.

### Corner radius

Sharp by default. Two exceptions only:

```swift
enum NordRadius {
    static let none: CGFloat = 0   // cards, buttons, badges, sheets
    static let pill: CGFloat = 999 // search field, capsule chips, swatches (use 50% for circles)
    static let avatar: CGFloat = 999
}
```

Do not introduce `8pt` or `12pt` rounded rectangles — they read as generic iOS, not Nordstrom.

### Dividers & borders

- Hairline: `Rectangle().fill(.nordGray200).frame(height: 1)` — width is full bleed.
- Input border: `RoundedRectangle(cornerRadius: 999).stroke(.nordGray300, lineWidth: 1)` for pills, else `Rectangle().stroke(.nordGray300, lineWidth: 1)`.

### Elevation

No shadows. If you must lift something (modal sheets), let the system sheet do it; don't add custom `.shadow()`.

---

## 5. Components

### 5.1 Primary button (CTA)

Black, full-width on phone, uppercase, tracked.

```swift
struct NordPrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(NordType.cta)
                .tracking(1.1)
                .textCase(.uppercase)
                .foregroundStyle(Color.nordWhite)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(Color.nordBlack)
        }
        .buttonStyle(.plain)
    }
}
```

Pressed state: `Color.nordGray700`. Disabled: `Color.nordGray300` background, `Color.nordGray500` text. No corner radius.

### 5.2 Secondary / outline button

```swift
struct NordOutlineButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(NordType.cta)
                .tracking(1.1)
                .textCase(.uppercase)
                .foregroundStyle(Color.nordBlack)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(Color.nordWhite)
                .overlay(Rectangle().stroke(Color.nordBlack, lineWidth: 2))
        }
        .buttonStyle(.plain)
    }
}
```

### 5.3 Text link

Inline, underlined on hover/press. Use `.underline()` and `Color.nordBlack` (or `.nordLink` for informational).

### 5.4 Search field (pill)

```swift
HStack(spacing: 8) {
    Image(systemName: "magnifyingglass").foregroundStyle(Color.nordGray500)
    TextField("Search", text: $query)
        .font(NordType.bodySmall)
}
.padding(.horizontal, 14)
.padding(.vertical, 8)
.overlay(
    RoundedRectangle(cornerRadius: 999)
        .stroke(Color.nordGray300, lineWidth: 1)
)
```

Focused state: stroke becomes `Color.nordBlack`.

### 5.5 Product card

```
+--------------------------+
|                          |  <- 4:3-ish image well, gray-100 bg
|     [image / placeholder]|     aspect ratio 3:4 (133% padding)
|                          |     overlay: top-left badges, top-right wishlist heart
+--------------------------+
BRAND NAME                    <- caption, uppercase, gray-600, tracking 0.5
Product title goes here…      <- bodySmall, black, max 2 lines
$99.00   $129.00              <- bold red sale + struck-through gray
● ● ● +3 colors               <- 14x14 circular swatches
```

```swift
struct ProductCard: View {
    let product: Product
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topLeading) {
                Color.nordGray100
                    .aspectRatio(3.0/4.0, contentMode: .fit)
                AsyncImage(url: product.imageURL) { $0.resizable().scaledToFill() } placeholder: { Color.clear }
                badges
            }
            .clipped()

            Text(product.brand.uppercased())
                .font(NordType.caption).tracking(0.5)
                .foregroundStyle(Color.nordGray600)
            Text(product.name)
                .font(NordType.bodySmall)
                .lineLimit(2)
            priceRow
        }
    }
}
```

Grid: `LazyVGrid` with 2 columns on phone, 3-4 on iPad. Horizontal spacing `NordSpace.sm`, vertical `NordSpace.lg`.

### 5.6 Badge / chip

```swift
Text("NEW")
    .font(NordType.badge)
    .tracking(0.5)
    .textCase(.uppercase)
    .foregroundStyle(Color.nordGray700)
    .padding(.horizontal, 8)
    .padding(.vertical, 2)
    .background(Color.nordWhite)
    .overlay(Rectangle().stroke(Color.nordGray300, lineWidth: 1))
```

Sale variant: red fill, white text, no stroke. Always uppercase, tracked.

### 5.7 Header / nav bar

iOS doesn't have a "site bar above nav bar" — collapse the web's three-row header into:

1. **Large title nav bar** — `.navigationTitle("NORDSTROM")` with `.navigationBarTitleDisplayMode(.inline)` and a custom title view (Lato Black 22pt, tracking 2.6).
2. **Search field** below as a sticky header on the home/category screen.
3. **Category tabs** as a horizontally-scrolling `ScrollView(.horizontal)` with 13pt links, 2pt black bottom border on the active tab.
4. **Tab bar** at bottom for Home / Stores / Bag / Account.

Cart badge: top-right of the bag icon, 16pt circle, black bg, white 10pt-bold count.

### 5.8 Section header

```swift
HStack(alignment: .firstTextBaseline) {
    Text("Trending Now")
        .font(NordType.h2)
    Spacer()
    Button("Shop All") { }
        .font(NordType.caption).tracking(1.0).textCase(.uppercase)
        .foregroundStyle(Color.nordBlack)
        .underline()
}
.padding(.horizontal, NordSpace.md)
.padding(.top, NordSpace.xl)
.padding(.bottom, NordSpace.md)
```

For editorial moments use `NordType.displaySmall` (serif) instead.

### 5.9 Forms

- Text fields: rectangular (no radius), 1px `nordGray300` bottom border only, label above in `NordType.caption` uppercase tracked.
- Errors: inline below, `NordType.caption`, `Color.nordRed`.
- No floating labels, no Material-style filled boxes.

### 5.10 Modals / sheets

System `.sheet` with `.presentationDetents([.medium, .large])`. Sheet content uses the same paddings as a screen. Dismiss action top-right as a plain "Close" text button (not an X icon) to match web patterns.

---

## 6. Iconography

Use **SF Symbols** for everything. Equivalent map for the web demo:

| Web          | SF Symbol                |
|--------------|--------------------------|
| Search       | `magnifyingglass`        |
| Heart/wish   | `heart` / `heart.fill`   |
| Bag          | `bag` / `bag.fill`       |
| User         | `person`                 |
| Store/pin    | `mappin.and.ellipse`     |
| Close        | `xmark`                  |
| Chevron      | `chevron.right` / `.down`|

Render at `Image(systemName:).font(.system(size: 18, weight: .regular))`. Use `.regular` weight; bold reads as childish here.

---

## 7. Motion

Quiet and short. The web uses 0.15s–0.4s. Mirror with:

```swift
.animation(.easeOut(duration: 0.2), value: state)
```

- **Press feedback** on cards/buttons: 0.95 scale, 0.15s.
- **Hover analog (haptic on tap):** `UIImpactFeedbackGenerator(style: .light)` on add-to-bag.
- **No bounce springs** on chrome. Reserve spring physics for cart-count badge updates.
- **No parallax**, no autoplay video on home — flat editorial layouts.

---

## 8. Imagery & content

- **Aspect ratios:** Product card image 3:4. Editorial banner 16:9. Lookbook 4:5.
- **Placeholders:** `nordGray100` fill with a serif italic letter glyph at 30% opacity (mirrors `placeholderText` in `ProductCard.module.css`). Don't show a generic broken-image icon.
- **No rounded image corners.** Bleeding edges, full-bleed hero.
- **Captions in editorial blocks** use the serif at 18-22pt, italic optional.

---

## 9. Dark mode

Support it, but treat it as inversion of the neutral ramp — *don't* introduce navy or warm grays.

| Light token   | Dark equivalent |
|---------------|-----------------|
| `nordWhite`   | `#0A0A0A`       |
| `nordBlack`   | `#FAFAFA`       |
| `nordGray50`  | `#141414`       |
| `nordGray100` | `#1C1C1C`       |
| `nordGray200` | `#262626` (dividers) |
| `nordGray600` | `#A3A3A3` (secondary copy) |
| `nordRed`     | `#FF5252` (accessibility-bumped) |

CTAs: invert — white background, black text in dark mode. Borders stay 1px.

---

## 10. Accessibility

- Min tap target 44×44pt. CTA height 48 satisfies this.
- Min body size 15pt. Allow Dynamic Type — wrap fonts with `.relativeTo:` if using custom fonts:
  ```swift
  Font.custom("Lato-Regular", size: 15, relativeTo: .body)
  ```
- Color contrast: `nordGray500` on white passes AA for ≥18pt only — don't use it for body copy. Use `nordGray600`+ for paragraph text.
- Sale price color (`nordRed` on white) passes AA at the bold weights used.
- All icon buttons need `.accessibilityLabel(...)`.

---

## 11. What to avoid

- iOS-default rounded buttons (`.buttonStyle(.borderedProminent)`).
- Drop shadows, neumorphism, gradient fills (except hero photography).
- Tinted backgrounds on cards.
- Sentence-case CTA buttons. Always uppercase + tracked.
- Material/Foundation blue accent. The "tint" of the app is **black**, not the system blue. Set `.tint(.nordBlack)` on the root view.
- Emoji icons. Use SF Symbols.
- Corner radii in the 4–24pt range. Either 0 or pill.

---

## 12. Quick checklist for the agent

When generating any new screen, the agent should verify:

- [ ] Background is `nordWhite` (or `nordGray50` for tinted sections).
- [ ] All button labels are uppercase with `.tracking(≥1.0)`.
- [ ] Headlines use serif **only** for editorial; sans-black for everything else.
- [ ] No `.cornerRadius(_:)` other than `0` or `999`.
- [ ] No `.shadow(...)`. Separation comes from 1px `nordGray200` rules.
- [ ] Sale prices red+bold; original prices struck-through gray.
- [ ] Tap targets ≥44pt; CTAs 48pt tall.
- [ ] Tint is `.nordBlack` at the root.
- [ ] Custom fonts registered in `Info.plist` (or system fallback explicit).

---

## 13. Reference: token-to-SwiftUI cheat sheet

```swift
// Drop this single file into a new SwiftUI project and you have the system.

import SwiftUI

extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8)  & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
    static let nordBlack   = Color(hex: 0x000000)
    static let nordWhite   = Color(hex: 0xFFFFFF)
    static let nordGray50  = Color(hex: 0xF9F9F9)
    static let nordGray100 = Color(hex: 0xF2F2F2)
    static let nordGray200 = Color(hex: 0xE5E5E5)
    static let nordGray300 = Color(hex: 0xD4D4D4)
    static let nordGray400 = Color(hex: 0xA3A3A3)
    static let nordGray500 = Color(hex: 0x737373)
    static let nordGray600 = Color(hex: 0x525252)
    static let nordGray700 = Color(hex: 0x404040)
    static let nordRed     = Color(hex: 0xCC0000)
    static let nordRedDark = Color(hex: 0xA50000)
    static let nordLink    = Color(hex: 0x0F6CBD)
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

enum NordType {
    static let display      = Font.system(size: 56, weight: .bold,    design: .serif)
    static let displaySmall = Font.system(size: 36, weight: .bold,    design: .serif)
    static let h1           = Font.system(size: 28, weight: .black)
    static let h2           = Font.system(size: 20, weight: .bold)
    static let h3           = Font.system(size: 16, weight: .bold)
    static let body         = Font.system(size: 15, weight: .regular)
    static let bodySmall    = Font.system(size: 13, weight: .regular)
    static let caption      = Font.system(size: 12, weight: .regular)
    static let micro        = Font.system(size: 11, weight: .regular)
    static let cta          = Font.system(size: 13, weight: .bold)
    static let badge        = Font.system(size: 10, weight: .bold)
}

extension View {
    /// Apply Nordstrom-flavor uppercase tracking to a Text-bearing view.
    func nordCaps(_ tracking: CGFloat = 1.0) -> some View {
        self.tracking(tracking).textCase(.uppercase)
    }
}
```

End of guide. Anything not covered: default to *less* — fewer colors, fewer radii, more whitespace.
