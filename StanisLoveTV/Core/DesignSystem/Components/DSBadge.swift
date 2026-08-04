import SwiftUI

/// All 7 badge styles from `Design System.dc.html`'s BADGES block, built as a
/// full speculative set per `design-system-components.md` Open Question 13/16 —
/// none has a real call site today (`Channel` has no `isAdult`/similar field),
/// this is a ready-to-use visual component waiting for the domain to catch up.
enum DSBadgeStyle: Hashable {
    case live
    case new
    case hd
    case fourK
    case premium
    /// Reuses the existing `Color.ds.badge.adultBackground/adultText` tokens
    /// from Iteration 1 — the one style in this set whose tokens already exist,
    /// even though the domain still has nothing to trigger it with.
    case adult
    case rec

    var label: String {
        switch self {
        case .live: "LIVE"
        case .new: "NEW"
        case .hd: "HD"
        case .fourK: "4K"
        case .premium: "★ PREMIUM"
        case .adult: "18+"
        case .rec: "REC"
        }
    }

    var foreground: Color {
        switch self {
        case .live, .new, .premium:
            Color.ds.text.primary
        case .hd:
            Color.ds.text.secondary
        case .fourK:
            // Mockup's only badge with dark-on-light text. `background.surface`
            // is reused here as a *text* color purely because the hex value
            // (#171723) matches — semantically unusual, but correct visually.
            Color.ds.background.surface
        case .adult:
            Color.ds.badge.adultText
        case .rec:
            Color.ds.accent.error
        }
    }

    var background: AnyShapeStyle {
        switch self {
        case .live:
            AnyShapeStyle(Color.ds.accent.error)
        case .new:
            // No standalone Color.ds.accent.* token for #B85CFF — it only exists
            // today baked into DSGradient/DSShadow.focusGlow, not as a flat color.
            AnyShapeStyle(Color(hex: "#B85CFF"))
        case .hd, .rec:
            AnyShapeStyle(Color.ds.background.elevated)
        case .fourK:
            AnyShapeStyle(Color.ds.accent.warning)
        case .premium:
            AnyShapeStyle(DSGradient.love)
        case .adult:
            AnyShapeStyle(Color.ds.badge.adultBackground)
        }
    }

    /// `rec` alone gets a small red dot ahead of its label.
    var hasLeadingDot: Bool { self == .rec }
}

/// Padding (5×12), corner radius (8px), and font (12pt/800) in the mockup don't
/// match any existing `DSSpacing`/`DSRadius`/`Font.ds` value — rounded to the
/// nearest existing spacing/radius tokens, and font falls back to a documented
/// one-off `.system` exception (no bundled font has an 800-weight instance at
/// this style; `Nunito-ExtraBold` is bundled but is a display face, a mismatch
/// for a small uppercase chip label) — per Open Question 16 resolution.
struct DSBadge: View {
    let style: DSBadgeStyle

    var body: some View {
        HStack(spacing: DSSpacing.xxs) {
            if style.hasLeadingDot {
                Circle()
                    .fill(Color.ds.accent.error)
                    .frame(width: 7, height: 7)
            }
            Text(style.label)
        }
        .font(.system(size: 12, weight: .heavy))
        .padding(.vertical, DSSpacing.xxs)
        .padding(.horizontal, DSSpacing.xs)
        .foregroundStyle(style.foreground)
        .background(style.background, in: RoundedRectangle(cornerRadius: DSRadius.s))
    }
}
