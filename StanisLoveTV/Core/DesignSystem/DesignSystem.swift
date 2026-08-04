/// Root namespace for StanisLoveTV's design tokens, derived from the designer's
/// `Design System.dc.html` mockup.
///
/// This is a token-only layer — colors, typography, spacing, radius, shadow,
/// animation, and gradients. Reusable components (buttons, cards, badges,
/// inputs) are a separate, later iteration and are not part of this namespace.
///
/// Token categories live in sibling files, each its own namespace:
/// - `Color.ds.*`      — `Color+DesignSystem.swift`
/// - `Font.ds.*`        — `Font+DesignSystem.swift`
/// - `DSSpacing.*`      — `DS+Spacing.swift`
/// - `DSRadius.*`       — `DS+Radius.swift`
/// - `DSSize.*`         — `DS+Size.swift` (component layout constants migrated from the old `TVSize`, not mockup tokens)
/// - `DSShadow.*`       — `DS+Shadow.swift`
/// - `DSAnimation.*`    — `DS+Animation.swift`
/// - `DSGradient.*`     — `DS+Gradient.swift`
///
/// Typography line-height reference (SwiftUI `Font` has no line-height API;
/// apply via `.lineSpacing()` on the text view when needed):
/// - hero: 56pt, largeTitle: 44pt, title: 36pt, headline: 28pt, body: 26pt, caption: 20pt
enum DS {}
