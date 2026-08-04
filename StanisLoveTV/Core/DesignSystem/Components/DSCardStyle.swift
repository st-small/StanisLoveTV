import SwiftUI

/// Reusable card chrome: hairline border + `DSShadow.card` drop shadow + the
/// tvOS focus effect. Styling-only — does NOT touch the caller's own layout or
/// background, so it composes with `ChannelCardView`'s existing logo-based
/// layout instead of redesigning it to the mockup's square chip style
/// (design-system-components.md Open Question 9).
struct DSCardStyle: ViewModifier {
    var isFocused: Bool
    var cornerRadius: CGFloat = DSRadius.s

    func body(content: Content) -> some View {
        content
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.ds.border.hairline, lineWidth: 1)
            }
            .shadow(
                color: DSShadow.card.color,
                radius: DSShadow.card.radius,
                x: DSShadow.card.x,
                y: DSShadow.card.y
            )
            .dsFocusable(isFocused, scale: DSFocusScale.card, cornerRadius: cornerRadius)
    }
}

extension View {
    func dsCardStyle(isFocused: Bool, cornerRadius: CGFloat = DSRadius.s) -> some View {
        modifier(DSCardStyle(isFocused: isFocused, cornerRadius: cornerRadius))
    }
}
