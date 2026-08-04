import CoreFoundation

/// Component layout constants migrated 1:1 from the old `Core/Constants/Spacing.swift`
/// `TVSize` enum. Not design-mockup tokens — these are specific to individual
/// components (channel card, add-playlist sheet, gate blur), kept here only so all
/// magic numbers live under `Core/DesignSystem/` after `Spacing.swift` is removed.
/// `thumbnailCornerRadius` is intentionally not duplicated — it equals `DSRadius.s` (12).
enum DSSize {
    static let channelCardWidth: CGFloat = 300
    static let channelCardHeight: CGFloat = 170
    static let sheetMaxWidth: CGFloat = 700
    static let gateBlurRadius: CGFloat = 20
}
