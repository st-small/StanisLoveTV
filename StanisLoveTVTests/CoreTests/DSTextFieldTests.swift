import SwiftUI
import Testing
@testable import StanisLoveTV

@Suite("DSTextField")
struct DSTextFieldTests {

    @Test("variants_arePlainAndSearchOnly")
    func variantsArePlainAndSearchOnly() {
        // .dropdown deliberately not implemented — no picker-style screen
        // exists yet to consume it (design-system-components.md Open Question 14).
        #expect(DSTextFieldVariant.plain != DSTextFieldVariant.search)
    }

    @Test("paddingAndRadius_matchMockupExactly")
    func paddingAndRadiusMatchMockupExactly() {
        // Open Question 9a originally rounded these to the nearest DSSpacing/
        // DSRadius tokens; overridden afterward — inputs are this iteration's
        // highest-priority visual target, so exact mockup values win over
        // reusing the general 8pt-grid scale.
        #expect(DSTextFieldMetrics.verticalPadding == 14)
        #expect(DSTextFieldMetrics.horizontalPadding == 18)
        #expect(DSTextFieldMetrics.cornerRadius == 14)
    }

    @Test("focusedBorder_usesInputGlowPreset_notStandardFocusGlow")
    func focusedBorderUsesInputGlowPresetNotStandardFocusGlow() {
        // The mockup's Focused input example is a single-color 2px border +
        // 16pt/0.5-alpha glow — a different, simpler visual language than
        // DSShadow.focusGlow (used by cards/buttons), not a reuse of it.
        #expect(DSInputFocusMetrics.borderColor == Color(hex: "#B85CFF"))
        #expect(DSInputFocusMetrics.borderWidth == 2)
        #expect(DSInputFocusMetrics.glowRadius == 16)
        #expect(DSInputFocusMetrics.glowOpacity == 0.5)
        #expect(DSInputFocusMetrics.glowRadius != DSShadow.focusGlow.radius)
    }
}
