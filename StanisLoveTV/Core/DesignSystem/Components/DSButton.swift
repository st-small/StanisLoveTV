import SwiftUI

/// Visual variants for `DSButtonStyle`, per `Design System.dc.html`'s BUTTONS block.
/// `.loading`/`.disabled` from the mockup are NOT separate cases here — they're
/// states layered on top of any variant (`isLoading` parameter / `@Environment(\.isEnabled)`),
/// not distinct chrome the caller picks — see `design-system-components.md` Компонент 2.
enum DSButtonVariant: Hashable {
    case primary
    case secondary
    case outline
    case ghost
    /// 44×44 visual circle — hit/focus area is expanded to 100×100 to satisfy
    /// `tvos-ui.md`'s "Minimum interactive target" rule without changing the
    /// mockup's visual size (design-system-components.md Open Question 6).
    case icon
}

struct DSButtonStyle: ButtonStyle {
    var variant: DSButtonVariant = .primary
    var isLoading: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        DSButtonBody(configuration: configuration, variant: variant, isLoading: isLoading)
    }
}

/// Sizing with no design-system token equivalent, named (not left as inline
/// literals) specifically so `DSButtonStyleTests` can assert on the 100pt
/// hit-target as a regression guard for Open Question 6, instead of only
/// being checkable by rendering.
enum DSButtonMetrics {
    static let iconVisualSize: CGFloat = 44
    static let iconHitAreaSize: CGFloat = 100
}

/// Chrome for one button state, resolved from variant + isLoading + isEnabled.
/// Pulled out of `DSButtonBody` into a standalone, non-private, side-effect-free
/// function specifically so tests can call the real resolution logic directly
/// instead of re-implementing (and potentially drifting from) it.
struct DSButtonChrome {
    let background: AnyShapeStyle
    let foreground: Color
    let borderColor: Color?

    static func resolve(variant: DSButtonVariant, isLoading: Bool, isEnabled: Bool) -> DSButtonChrome {
        // isLoading takes priority over isEnabled: a button that's disabled
        // *because* it's mid-submit (the real AddPlaylistView call site does
        // `.disabled(... || isAdding)`) must still show the spinner, not go
        // silently gray — otherwise the user gets no feedback that anything
        // is happening. A button disabled for any other reason (not loading)
        // falls through to the muted disabled chrome below.
        if isLoading {
            // Mockup shows only one Loading example, styled as the .secondary
            // chrome regardless of the button's real variant — intentional per plan.
            return DSButtonChrome(
                background: AnyShapeStyle(Color.ds.background.elevated),
                foreground: Color.ds.text.inactive,
                borderColor: nil
            )
        }
        guard isEnabled else {
            return DSButtonChrome(
                background: AnyShapeStyle(Color.ds.background.surface),
                foreground: Color.ds.text.disabled,
                borderColor: Color.ds.border.hairline
            )
        }
        switch variant {
        case .primary:
            return DSButtonChrome(
                background: AnyShapeStyle(DSGradient.love),
                foreground: Color.ds.text.primary,
                borderColor: nil
            )
        case .secondary:
            return DSButtonChrome(
                background: AnyShapeStyle(Color.ds.background.elevated),
                foreground: Color.ds.text.primary,
                borderColor: nil
            )
        case .outline:
            return DSButtonChrome(
                background: AnyShapeStyle(Color.clear),
                foreground: Color.ds.text.primary,
                borderColor: Color.white.opacity(0.25)
            )
        case .ghost:
            return DSButtonChrome(
                background: AnyShapeStyle(Color.clear),
                foreground: Color.ds.text.inactive,
                borderColor: nil
            )
        case .icon:
            return DSButtonChrome(
                background: AnyShapeStyle(Color.ds.background.elevated),
                foreground: Color.ds.text.secondary,
                borderColor: nil
            )
        }
    }
}

/// Separate `View` (not inlined in `makeBody`) — reading `@Environment(\.isFocused)`
/// requires a real view in the hierarchy; `ButtonStyleConfiguration` itself has no
/// focus property. This is the documented, if under-known, tvOS pattern for
/// focus-aware `ButtonStyle`s — see tvOS Considerations in the plan.
private struct DSButtonBody: View {
    let configuration: ButtonStyleConfiguration
    let variant: DSButtonVariant
    let isLoading: Bool

    @Environment(\.isFocused) private var isFocused
    @Environment(\.isEnabled) private var isEnabled

    /// No `Font.ds` token exists at 15pt/700 (button label size in the mockup
    /// doesn't match any of hero/largeTitle/title/headline/body/caption) — reuse
    /// the already-bundled, already-registered `Inter-Bold.ttf` directly rather
    /// than falling back to a system font or adding a single-use `Font.ds` case.
    private static let labelFont = Font.custom("Inter-Bold", size: 15)

    private var isIcon: Bool { variant == .icon }

    var body: some View {
        content
            .font(Self.labelFont)
            .padding(.vertical, isIcon ? 0 : DSSpacing.s)
            .padding(.horizontal, isIcon ? 0 : DSSpacing.l)
            .frame(width: isIcon ? DSButtonMetrics.iconVisualSize : nil, height: isIcon ? DSButtonMetrics.iconVisualSize : nil)
            .foregroundStyle(chrome.foreground)
            .background(chrome.background, in: shape)
            .overlay {
                if let borderColor = chrome.borderColor {
                    shape.stroke(borderColor, lineWidth: 1)
                }
            }
            .dsFocusable(isFocused, scale: DSFocusScale.button, cornerRadius: isIcon ? DSButtonMetrics.iconVisualSize / 2 : DSRadius.s)
            // Expand the focusable/hit region to 100×100 for icon buttons AFTER
            // dsFocusable draws its ring around the true 44×44 visual — order
            // matters, reversing it would stretch the ring to 100×100 too.
            .frame(
                minWidth: isIcon ? DSButtonMetrics.iconHitAreaSize : nil,
                minHeight: isIcon ? DSButtonMetrics.iconHitAreaSize : nil
            )
            .contentShape(Rectangle())
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(DSAnimation.fast, value: configuration.isPressed)
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            HStack(spacing: DSSpacing.xs) {
                ProgressView()
                    .tint(Color.ds.text.inactive)
                Text("Загрузка...")
            }
        } else {
            configuration.label
        }
    }

    private var shape: AnyShape {
        isIcon ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: DSRadius.s))
    }

    private var chrome: DSButtonChrome {
        DSButtonChrome.resolve(variant: variant, isLoading: isLoading, isEnabled: isEnabled)
    }
}
