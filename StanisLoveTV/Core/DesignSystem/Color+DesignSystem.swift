import SwiftUI

extension Color {
    /// Parses a `"#RRGGBB"` hex string. The design-system palette below is a fixed
    /// set of known-valid literals, so a malformed hex here means a typo in this
    /// file, not bad external input — falls back to `.clear` rather than crashing
    /// in release; `DesignSystemTokensTests` catches the typo case in CI.
    init(hex: String) {
        var sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if sanitized.hasPrefix("#") {
            sanitized.removeFirst()
        }

        guard sanitized.count == 6, let value = UInt64(sanitized, radix: 16) else {
            self = .clear
            return
        }

        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255
        self = Color(red: red, green: green, blue: blue)
    }

    enum ds {
        enum background {
            static let primary = Color(hex: "#0C0C12")
            static let surface = Color(hex: "#171723")
            static let elevated = Color(hex: "#212132")
            static let overlay = Color.black.opacity(0.55)
        }

        enum text {
            static let primary = Color(hex: "#FFFFFF")
            static let secondary = Color(hex: "#C7C8D1")
            static let inactive = Color(hex: "#8B8C99")
            static let disabled = Color(hex: "#5A5A66")
        }

        enum accent {
            static let success = Color(hex: "#3ED07F")
            static let warning = Color(hex: "#FFB020")
            static let error = Color(hex: "#FF5757")
            static let info = Color(hex: "#5FB7FF")
        }

        enum badge {
            static let adultBackground = Color(hex: "#3B2130")
            static let adultText = Color(hex: "#FF8FB8")
        }

        enum border {
            static let hairline = Color.white.opacity(0.08)
        }
    }
}
