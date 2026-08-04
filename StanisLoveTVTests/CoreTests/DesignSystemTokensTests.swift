import SwiftUI
import Testing
import UIKit
@testable import StanisLoveTV

@Suite("DesignSystemTokens")
struct DesignSystemTokensTests {

    // MARK: - Color

    @Test("allColorTokensAreDistinctAndNonNil")
    func allColorTokensAreDistinctAndNonNil() {
        #expect(Color.ds.text.primary != Color.ds.background.primary)
        #expect(Color.ds.text.secondary != Color.ds.background.surface)
        #expect(Color.ds.accent.success != Color.ds.accent.error)
        #expect(Color.ds.accent.warning != Color.ds.accent.info)
        #expect(Color.ds.badge.adultBackground != Color.ds.badge.adultText)
    }

    @Test("hexColorInitializer_parsesKnownValues")
    func hexColorInitializerParsesKnownValues() {
        #expect(Color(hex: "#FF3D9A") != .clear)
        #expect(Color(hex: "#FF3D9A") == Color(hex: "#FF3D9A"))
    }

    @Test("hexColorInitializer_malformedHex_doesNotCrash")
    func hexColorInitializerMalformedHexDoesNotCrash() {
        #expect(Color(hex: "bad") == .clear)
        #expect(Color(hex: "#12345") == .clear)
        #expect(Color(hex: "") == .clear)
    }

    // MARK: - Font

    @Test("customFontsAreRegisteredInBundle")
    func customFontsAreRegisteredInBundle() {
        let postscriptNames = [
            "Nunito-Regular", "Nunito-SemiBold", "Nunito-Bold", "Nunito-ExtraBold",
            "Inter-Regular", "Inter-Medium", "Inter-SemiBold", "Inter-Bold",
        ]
        for name in postscriptNames {
            #expect(UIFont(name: name, size: 12) != nil, "\(name) is not registered — check UIAppFonts in Info.plist")
        }
    }

    @Test("fontDSTokens_haveDistinctValues")
    func fontDSTokensHaveDistinctValues() {
        #expect(Font.ds.hero != Font.ds.body)
        #expect(Font.ds.largeTitle != Font.ds.title)
        #expect(Font.ds.headline != Font.ds.caption)
    }

    @Test("fontDSTokens_fallBackGracefully_whenFontMissing")
    func fontDSTokensFallBackGracefullyWhenFontMissing() {
        // `Font.custom` is evaluated lazily by SwiftUI at render time, not at
        // construction — an unregistered PostScript name never throws or crashes,
        // it silently falls back to the system font. This test documents that
        // guarantee using a name that is deliberately never registered in
        // Info.plist's UIAppFonts, mirroring how Font.ds.* would behave if a
        // font ever failed to bundle (see Risk 1 in the design-system-tokens plan).
        let missingFontName = "StanisLoveTV-DefinitelyMissingFont"
        #expect(UIFont(name: missingFontName, size: 12) == nil, "sanity check: name must actually be unregistered")

        let font = Font.custom(missingFontName, size: 20, relativeTo: .body)
        _ = font // constructing/using a Font with a missing PostScript name must not crash
    }

    // MARK: - Spacing

    @Test("spacingTokens_areMonotonicallyIncreasing")
    func spacingTokensAreMonotonicallyIncreasing() {
        let scale = [
            DSSpacing.xxs, DSSpacing.xs, DSSpacing.s, DSSpacing.m,
            DSSpacing.l, DSSpacing.xl, DSSpacing.xxl, DSSpacing.xxxl,
        ]
        #expect(scale == scale.sorted())
        #expect(Set(scale).count == scale.count)
    }

    // MARK: - Radius

    @Test("radiusTokens_matchDesignMockValues")
    func radiusTokensMatchDesignMockValues() {
        #expect(DSRadius.s == 12)
        #expect(DSRadius.m == 18)
        #expect(DSRadius.l == 24)
        #expect(DSRadius.xl == 40)
    }

    // MARK: - Size

    @Test("sizeTokens_matchLegacyTVSizeValues")
    func sizeTokensMatchLegacyTVSizeValues() {
        #expect(DSSize.channelCardWidth == 300)
        #expect(DSSize.channelCardHeight == 170)
        #expect(DSSize.sheetMaxWidth == 700)
        #expect(DSSize.gateBlurRadius == 20)
    }

    // MARK: - Shadow

    @Test("shadowTokens_haveExpectedRadiusAndOpacity")
    func shadowTokensHaveExpectedRadiusAndOpacity() {
        #expect(DSShadow.card.radius == 24)
        #expect(DSShadow.card.color == Color.black.opacity(0.4))
        #expect(DSShadow.hero.radius == 30)
        #expect(DSShadow.hero.color == Color.black.opacity(0.5))
        #expect(DSShadow.floating.radius == 60)
        #expect(DSShadow.floating.color == Color.black.opacity(0.6))
        #expect(DSShadow.focusGlow.glowColor != nil)
    }

    // MARK: - Animation

    @Test("animationTokens_haveExpectedDurations")
    func animationTokensHaveExpectedDurations() {
        #expect(DSAnimation.fast == Animation.easeOut(duration: 0.25))
        #expect(DSAnimation.normal == Animation.easeOut(duration: 0.35))
        #expect(DSAnimation.slow == Animation.easeInOut(duration: 0.6))
    }

    // MARK: - Gradient

    @Test("gradientTokensExist")
    func gradientTokensExist() {
        _ = DSGradient.love
        _ = DSGradient.dark
        _ = DSGradient.glow
    }

    @Test("gradientTokens_containExpectedStopColors")
    func gradientTokensContainExpectedStopColors() {
        #expect(DSGradient.loveStops == [
            Color(hex: "#FF3D9A"), Color(hex: "#B85CFF"), Color(hex: "#3B82FF"),
        ])
        #expect(DSGradient.darkStops == [
            Color(hex: "#241938"), Color(hex: "#0C0C12"),
        ])
        #expect(DSGradient.glowStops == [
            Color(hex: "#FF3D9A"), Color(hex: "#3B82FF"),
        ])
    }
}
