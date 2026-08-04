import SwiftUI

/// Brand gradients from `Design System.dc.html`'s ЦВЕТА/ГРАДИЕНТЫ block.
/// `.glow` is the color gradient only — the mockup's `blur(1px)` + purple
/// box-shadow around it are presentation effects for a future `.dsFocusable()`
/// component, not part of this token (mirrors `DSShadow.focusGlow` scoping).
enum DSGradient {
    /// Raw stop colors backing `.love`, in order — kept separate from the
    /// `LinearGradient` value so tests can assert on stop colors directly;
    /// `LinearGradient` itself does not expose its input colors for introspection.
    static let loveStops: [Color] = [Color(hex: "#FF3D9A"), Color(hex: "#B85CFF"), Color(hex: "#3B82FF")]

    /// Raw stop colors backing `.dark`, in order.
    static let darkStops: [Color] = [Color(hex: "#241938"), Color(hex: "#0C0C12")]

    /// Raw stop colors backing `.glow`, in order.
    static let glowStops: [Color] = [Color(hex: "#FF3D9A"), Color(hex: "#3B82FF")]

    /// `linear-gradient(90deg, #FF3D9A, #B85CFF, #3B82FF)` — primary brand identity gradient.
    static let love = LinearGradient(colors: loveStops, startPoint: .leading, endPoint: .trailing)

    /// `linear-gradient(135deg, #241938, #0C0C12)` — screen background gradient.
    static let dark = LinearGradient(colors: darkStops, startPoint: .topLeading, endPoint: .bottomTrailing)

    /// `linear-gradient(90deg, #FF3D9A, #3B82FF)` — focus/glow accent gradient.
    static let glow = LinearGradient(colors: glowStops, startPoint: .leading, endPoint: .trailing)
}
