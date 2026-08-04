import SwiftUI
import Testing
@testable import StanisLoveTV

@Suite("DSBadge")
struct DSBadgeTests {

    private let allStyles: [DSBadgeStyle] = [.live, .new, .hd, .fourK, .premium, .adult, .rec]

    @Test("allBadgeStyles_areDistinctCases")
    func allBadgeStylesAreDistinctCases() {
        #expect(Set(allStyles).count == 7)
    }

    @Test("allBadgeStyles_haveNonEmptyLabels")
    func allBadgeStylesHaveNonEmptyLabels() {
        for style in allStyles {
            #expect(!style.label.isEmpty, "style: \(style)")
        }
    }

    @Test("fourKBadge_usesDarkTextOnLightBackground")
    func fourKBadgeUsesDarkTextOnLightBackground() {
        // The mockup's only badge with dark-on-light text — regression guard
        // against accidentally "fixing" it to match the other 6 light-on-dark styles.
        #expect(DSBadgeStyle.fourK.foreground == Color.ds.background.surface)
    }

    @Test("adultBadge_reusesExistingDesignSystemTokens")
    func adultBadgeReusesExistingDesignSystemTokens() {
        // The one style whose tokens already existed before this iteration
        // (Color.ds.badge.adultBackground/adultText, from Iteration 1).
        #expect(DSBadgeStyle.adult.foreground == Color.ds.badge.adultText)
    }

    @Test("recBadge_isTheOnlyStyleWithLeadingDot")
    func recBadgeIsTheOnlyStyleWithLeadingDot() {
        for style in allStyles {
            #expect(style.hasLeadingDot == (style == .rec), "style: \(style)")
        }
    }
}
