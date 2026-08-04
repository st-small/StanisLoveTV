import SwiftUI
import Testing
@testable import StanisLoveTV

@Suite("DSFocus")
struct DSFocusTests {

    @Test("focusScaleTokens_matchMockupValues")
    func focusScaleTokensMatchMockupValues() {
        #expect(DSFocusScale.card == 1.08)
        #expect(DSFocusScale.button == 1.06)
        #expect(DSFocusScale.chip == 1.05)
    }

    @Test("focusScaleTokens_areOrderedCardLargestChipSmallest")
    func focusScaleTokensAreOrdered() {
        // Regression guard: cards get the most visual emphasis on focus, chips
        // the least — see design-system-components.md Open Question 2.
        #expect(DSFocusScale.card > DSFocusScale.button)
        #expect(DSFocusScale.button > DSFocusScale.chip)
    }

    // NOTE: `.dsFocusable()`/`.dsSelected()` are `ViewModifier`s applying
    // scale/overlay/shadow — the project has no snapshot-testing or
    // ViewInspector dependency, so whether the modifier chain actually renders
    // the ring/glow/scale on screen is verified manually in Simulator, not
    // here (see design-system-components.md "Tests to Write" — Ограничение
    // тестируемости). These tests cover the token values the modifier reads.
}
