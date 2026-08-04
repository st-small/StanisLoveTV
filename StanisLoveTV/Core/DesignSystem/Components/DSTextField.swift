import SwiftUI

/// Visual variants for `DSTextField`, per `Design System.dc.html`'s INPUTS block.
/// `.dropdown` (trailing chevron, label/value row — e.g. "Качество: Лучшее") is
/// deliberately not implemented: there's no picker-style screen in the app today
/// to consume it — see `design-system-components.md` Open Question 14.
enum DSTextFieldVariant: Equatable {
    case plain
    case search
}

/// Exact mockup values (14px vertical / 18px horizontal padding, 14px radius).
/// None of these matches `DSSpacing`'s 8pt-grid scale (4/8/16/20/24/32/40/48)
/// or `DSRadius`'s scale (12/18/24/40) — Open Question 9a originally rounded
/// these to the nearest existing tokens (`DSSpacing.s`/`.m`, `DSRadius.m`), but
/// that decision was overridden: inputs are the highest-priority visual target
/// of this iteration (the literal screenshot that kicked it off), so pixel
/// accuracy here outranks reusing the general scale. Dedicated one-off
/// constants, not new entries on `DSSpacing`/`DSRadius` — they don't belong to
/// the 8pt-grid family and shouldn't pretend to. Not private — `DSTextFieldTests`
/// asserts these exact values directly.
enum DSTextFieldMetrics {
    static let verticalPadding: CGFloat = 14
    static let horizontalPadding: CGFloat = 18
    static let cornerRadius: CGFloat = 14
}

/// Base chrome shared by every field, plus its own focus visual language
/// (`.dsFocusable(preset: .input)`) — distinct from `.dsFocusable(preset: .standard)`
/// used by cards/buttons. `isFocused` is supplied by the caller, same contract as
/// `.dsFocusable()`: this view does not own a `@FocusState` itself, the caller
/// applies `.focused($binding, equals:)` to the `DSTextField` instance for the
/// actual keyboard focus AND passes the resulting Bool here for the glow to react to.
struct DSTextField: View {
    var variant: DSTextFieldVariant = .plain
    let placeholder: String
    @Binding var text: String
    var isFocused: Bool = false

    var body: some View {
        HStack(spacing: DSSpacing.xs) {
            if variant == .search {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.ds.text.inactive)
                    .accessibilityHidden(true)
            }

            // Mockup's .plain example uses a dimmer placeholder color (#5A5A66,
            // text.disabled) than .search (#8B8C99, text.inactive) — almost
            // certainly a mockup inconsistency, not an intentional distinction
            // (no design-system note explains why an empty plain field should
            // read as "more disabled" than an empty search field). Standardized
            // on text.inactive for both.
            //
            // Font: mockup uses 14px/Inter-Regular for input text — no Font.ds
            // token matches that exactly, but `.ds.caption` (15pt/Inter-Regular)
            // is the same weight one point off, close enough to reuse rather than
            // add another one-off literal. Without an explicit font here, tvOS
            // falls back to its (much larger) system default, which visually
            // swallows the field's own padding — this was the actual cause of
            // "no text padding", not the padding values themselves.
            TextField(
                "",
                text: $text,
                prompt: Text(placeholder).foregroundStyle(Color.ds.text.inactive)
            )
            .font(.ds.caption)
            .foregroundStyle(Color.ds.text.primary)
            .textFieldStyle(.plain)
        }
        .padding(.vertical, DSTextFieldMetrics.verticalPadding)
        .padding(.horizontal, DSTextFieldMetrics.horizontalPadding)
        // Mockup literally specifies `background:#0C0C12` (Color.ds.background.primary)
        // — an opaque fill. Deliberately overridden to transparent: DSTextField is
        // always placed on top of an already-opaque/material container in this app
        // (AddPlaylistView's .regularMaterial card, tvOS's own sheet chrome), and
        // stacking our own solid near-black fill on top of that reads as a heavy,
        // separate gray box rather than a field embedded in its surroundings. The
        // hairline border alone defines the field's edges; the real background
        // shows through.
        .background(Color.clear, in: RoundedRectangle(cornerRadius: DSTextFieldMetrics.cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: DSTextFieldMetrics.cornerRadius)
                .stroke(Color.ds.border.hairline, lineWidth: 1)
        }
        .dsFocusable(isFocused, cornerRadius: DSTextFieldMetrics.cornerRadius, preset: .input)
    }
}
