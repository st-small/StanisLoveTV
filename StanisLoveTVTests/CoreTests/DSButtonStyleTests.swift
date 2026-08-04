import SwiftUI
import Testing
@testable import StanisLoveTV

@Suite("DSButtonStyle")
struct DSButtonStyleTests {

    @Test("secondaryVariant_matchesBackgroundElevated")
    func secondaryVariantMatchesBackgroundElevated() {
        let chrome = DSButtonChrome.resolve(variant: .secondary, isLoading: false, isEnabled: true)
        #expect(chrome.foreground == Color.ds.text.primary)
        #expect(chrome.borderColor == nil)
    }

    @Test("ghostVariant_usesInactiveTextColor")
    func ghostVariantUsesInactiveTextColor() {
        let chrome = DSButtonChrome.resolve(variant: .ghost, isLoading: false, isEnabled: true)
        #expect(chrome.foreground == Color.ds.text.inactive)
    }

    @Test("outlineVariant_usesQuarterOpacityWhiteBorder")
    func outlineVariantUsesQuarterOpacityWhiteBorder() {
        let chrome = DSButtonChrome.resolve(variant: .outline, isLoading: false, isEnabled: true)
        #expect(chrome.borderColor == Color.white.opacity(0.25))
    }

    @Test("disabledState_overridesVariantColors_regardlessOfVariant")
    func disabledStateOverridesVariantColors() {
        for variant: DSButtonVariant in [.primary, .secondary, .outline, .ghost, .icon] {
            let chrome = DSButtonChrome.resolve(variant: variant, isLoading: false, isEnabled: false)
            #expect(chrome.foreground == Color.ds.text.disabled, "variant: \(variant)")
            #expect(chrome.borderColor == Color.ds.border.hairline, "variant: \(variant)")
        }
    }

    @Test("loadingState_takesPriorityOverDisabled")
    func loadingStateTakesPriorityOverDisabled() {
        // AddPlaylistView's real call site disables the button *while* isLoading
        // is true (`.disabled(... || isAdding)`) — the spinner chrome must still
        // win, otherwise the user gets no feedback mid-submit. See DSButton.swift.
        let chrome = DSButtonChrome.resolve(variant: .primary, isLoading: true, isEnabled: false)
        #expect(chrome.foreground == Color.ds.text.inactive)
        #expect(chrome.foreground != Color.ds.text.disabled)
    }

    @Test("iconVariant_hasMinimumHitTarget100pt")
    func iconVariantHasMinimumHitTarget100pt() {
        // Regression guard for design-system-components.md Open Question 6:
        // the icon button stays visually 44×44 but its focus/hit area must be
        // expanded to at least 100×100 to satisfy tvos-ui.md.
        #expect(DSButtonMetrics.iconVisualSize == 44)
        #expect(DSButtonMetrics.iconHitAreaSize >= 100)
    }

    @Test("allVariants_areDistinctCases")
    func allVariantsAreDistinctCases() {
        let variants: [DSButtonVariant] = [.primary, .secondary, .outline, .ghost, .icon]
        #expect(Set(variants).count == 5)
    }
}
