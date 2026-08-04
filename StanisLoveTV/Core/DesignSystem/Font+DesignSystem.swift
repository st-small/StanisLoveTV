import SwiftUI
import UIKit

extension Font {
    enum ds {
        // Nunito — заголовки
        static let hero = Font.custom("Nunito-ExtraBold", size: 48, relativeTo: .largeTitle)
        static let largeTitle = Font.custom("Nunito-Bold", size: 36, relativeTo: .title)
        static let title = Font.custom("Nunito-Bold", size: 28, relativeTo: .title2)
        // Inter — весь остальной текст
        static let headline = Font.custom("Inter-SemiBold", size: 22, relativeTo: .headline)
        static let body = Font.custom("Inter-Regular", size: 18, relativeTo: .body)
        static let caption = Font.custom("Inter-Regular", size: 15, relativeTo: .caption)
    }

    /// All 8 PostScript names backing `Font.ds.*`, registered via `UIAppFonts` in Info.plist.
    private static let designSystemPostScriptNames = [
        "Nunito-Regular", "Nunito-SemiBold", "Nunito-Bold", "Nunito-ExtraBold",
        "Inter-Regular", "Inter-Medium", "Inter-SemiBold", "Inter-Bold",
    ]

    /// DEBUG-only sanity check: warns if any design-system font failed to register
    /// via `UIAppFonts`. A missing font does not crash — `Font.custom` silently
    /// falls back to the system font — so this is the only signal that catches it.
    static func registerDesignSystemFonts() {
        #if DEBUG
        for name in designSystemPostScriptNames where UIFont(name: name, size: 12) == nil {
            print("⚠️ DesignSystem: font \"\(name)\" is not registered — check UIAppFonts in Info.plist")
        }
        #endif
    }
}
