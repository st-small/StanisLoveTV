import SwiftUI

struct DSShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
    /// nil for ordinary shadows; set for focus-glow effects in future components.
    let glowColor: Color?
}

enum DSShadow {
    static let card = DSShadowStyle(color: .black.opacity(0.4), radius: 24, x: 0, y: 8, glowColor: nil)
    static let hero = DSShadowStyle(color: .black.opacity(0.5), radius: 30, x: 0, y: 20, glowColor: nil)
    static let floating = DSShadowStyle(color: .black.opacity(0.6), radius: 60, x: 0, y: 30, glowColor: nil)

    /// Structure only — not applied anywhere yet. Real usage (`.scaleEffect` +
    /// `.shadow` on `.focused`) belongs to a future `.dsFocusable()` component modifier.
    static let focusGlow = DSShadowStyle(
        color: Color(hex: "#B85CFF").opacity(0.6),
        radius: 32,
        x: 0,
        y: 0,
        glowColor: Color(hex: "#FF3D9A")
    )
}
