import SwiftUI

/// Fixed scale factors for the tvOS focus effect, one per mockup component type.
/// Cards get the largest scale (1.08); buttons and small chips use progressively
/// smaller scales so they don't dominate their surrounding layout when focused.
enum DSFocusScale {
    static let card: CGFloat = 1.08
    static let button: CGFloat = 1.06
    static let chip: CGFloat = 1.05
}

/// Metrics with no design-system token equivalent — hardcoded here rather than
/// promoted to `DSSpacing`/`DSRadius`, per `design-system-components.md` Open
/// Question 16 (one-off literals are fine for values that don't recur elsewhere).
private enum DSFocusMetrics {
    static let ringLineWidth: CGFloat = 3      // mockup: `0 0 0 3px` focus ring
    static let selectedRingLineWidth: CGFloat = 2
    static let checkmarkBadgeSize: CGFloat = 22
}

/// Which focus visual language `.dsFocusable()` renders.
enum DSFocusPreset {
    /// Two-layer ring (`DSShadow.focusGlow.glowColor`, 3px) + soft glow
    /// (`DSShadow.focusGlow.color`, 32pt blur) + scale. Cards, buttons, chips.
    case standard
    /// Single-color 2px border + a smaller, softer glow, no scale — scaling a
    /// text field while the user is typing would be distracting. Values come
    /// directly from the mockup's Inputs "Focused" example
    /// (`border:2px solid #B85CFF; box-shadow:0 0 16px rgba(184,92,255,.5)`),
    /// a deliberately different, simpler visual language than `DSShadow.focusGlow`
    /// — see `design-system-components.md` Компонент 3 for the reasoning.
    case input
}

/// Not private — `DSTextFieldTests` asserts these against the mockup's Inputs
/// "Focused" example values directly, as a regression guard.
enum DSInputFocusMetrics {
    static let borderColor = Color(hex: "#B85CFF")
    static let borderWidth: CGFloat = 2
    static let glowRadius: CGFloat = 16
    static let glowOpacity: Double = 0.5
}

extension View {
    /// Applies the StanisLoveTV tvOS focus effect: scale + a solid accent ring
    /// (`DSShadow.focusGlow.glowColor`) + a soft colored glow (`DSShadow.focusGlow.color`).
    ///
    /// Presentation-only — this modifier does **not** call `.focusable()`/`.focused()`
    /// itself. The caller owns focus state (`@FocusState`, a comparison against an
    /// enum case, or `@Environment(\.isFocused)` inside a `ButtonStyle`) and passes
    /// the resulting `Bool` in. Applying `.dsFocusable()` to a view that isn't
    /// actually focusable is a silent visual no-op, not a compile error — the
    /// effect simply never turns on.
    func dsFocusable(
        _ isFocused: Bool,
        scale: CGFloat = DSFocusScale.card,
        cornerRadius: CGFloat = DSRadius.s,
        preset: DSFocusPreset = .standard
    ) -> some View {
        modifier(DSFocusableModifier(isFocused: isFocused, scale: scale, cornerRadius: cornerRadius, preset: preset))
    }

    /// Applies the StanisLoveTV "selected" indicator: a persistent success-green
    /// ring + a small checkmark badge in the top-trailing corner. Unlike
    /// `.dsFocusable()`, this marks a standing state (e.g. the active playlist
    /// row) rather than a transient focus effect, and intentionally does not
    /// animate on its own — the caller's own state change (if any) drives that.
    func dsSelected(_ isSelected: Bool, cornerRadius: CGFloat = DSRadius.s) -> some View {
        modifier(DSSelectedModifier(isSelected: isSelected, cornerRadius: cornerRadius))
    }
}

private struct DSFocusableModifier: ViewModifier {
    let isFocused: Bool
    let scale: CGFloat
    let cornerRadius: CGFloat
    var preset: DSFocusPreset = .standard

    func body(content: Content) -> some View {
        switch preset {
        case .standard:
            content
                .scaleEffect(isFocused ? scale : 1.0)
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            DSShadow.focusGlow.glowColor ?? .clear,
                            lineWidth: isFocused ? DSFocusMetrics.ringLineWidth : 0
                        )
                }
                .shadow(
                    color: isFocused ? DSShadow.focusGlow.color : .clear,
                    radius: DSShadow.focusGlow.radius,
                    x: DSShadow.focusGlow.x,
                    y: DSShadow.focusGlow.y
                )
                .animation(DSAnimation.fast, value: isFocused)
        case .input:
            content
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            isFocused ? DSInputFocusMetrics.borderColor : .clear,
                            lineWidth: isFocused ? DSInputFocusMetrics.borderWidth : 0
                        )
                }
                .shadow(
                    color: isFocused ? DSInputFocusMetrics.borderColor.opacity(DSInputFocusMetrics.glowOpacity) : .clear,
                    radius: DSInputFocusMetrics.glowRadius,
                    x: 0,
                    y: 0
                )
                .animation(DSAnimation.fast, value: isFocused)
        }
    }
}

private struct DSSelectedModifier: ViewModifier {
    let isSelected: Bool
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        Color.ds.accent.success,
                        lineWidth: isSelected ? DSFocusMetrics.selectedRingLineWidth : 0
                    )
            }
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    // Decorative — the "selected" semantic belongs in the caller's
                    // own accessibilityLabel/Value (tvos-ui.md), not this glyph;
                    // otherwise VoiceOver announces a stray "checkmark" with no context.
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.ds.background.primary)
                        .frame(width: DSFocusMetrics.checkmarkBadgeSize, height: DSFocusMetrics.checkmarkBadgeSize)
                        .background(Color.ds.accent.success, in: Circle())
                        .padding(DSSpacing.xs)
                        .accessibilityHidden(true)
                }
            }
    }
}
