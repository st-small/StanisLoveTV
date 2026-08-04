import SwiftUI

/// Debug-only catalog of every `Core/DesignSystem/*` token with a live, on-device
/// usage example — colors, typography, spacing, radius, size, shadow, animation,
/// gradient. Not wired into any navigation flow by design; intended to be pushed
/// from a developer menu (see `.claude/plans/design-system-tokens.md`) so the full
/// token set can be eyeballed on a real TV without hunting through call sites.
struct DesignSystemShowcaseView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xxl) {
                colorSection
                typographySection
                spacingSection
                radiusSection
                sizeSection
                shadowSection
                animationSection
                gradientSection
                focusSection
                buttonSection
                textFieldSection
                cardSection
                badgeSection
            }
            .padding(DSSpacing.xxxl)
        }
        .background(Color.ds.background.primary.ignoresSafeArea())
    }

    // MARK: - Colors

    private var colorSection: some View {
        SectionContainer(title: "Color.ds") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: DSSpacing.s)], spacing: DSSpacing.s) {
                ColorSwatch(name: "background.primary", color: Color.ds.background.primary)
                ColorSwatch(name: "background.surface", color: Color.ds.background.surface)
                ColorSwatch(name: "background.elevated", color: Color.ds.background.elevated)
                ColorSwatch(name: "background.overlay", color: Color.ds.background.overlay)
                ColorSwatch(name: "text.primary", color: Color.ds.text.primary)
                ColorSwatch(name: "text.secondary", color: Color.ds.text.secondary)
                ColorSwatch(name: "text.inactive", color: Color.ds.text.inactive)
                ColorSwatch(name: "text.disabled", color: Color.ds.text.disabled)
                ColorSwatch(name: "accent.success", color: Color.ds.accent.success)
                ColorSwatch(name: "accent.warning", color: Color.ds.accent.warning)
                ColorSwatch(name: "accent.error", color: Color.ds.accent.error)
                ColorSwatch(name: "accent.info", color: Color.ds.accent.info)
                ColorSwatch(name: "badge.adultBackground", color: Color.ds.badge.adultBackground)
                ColorSwatch(name: "badge.adultText", color: Color.ds.badge.adultText)
                ColorSwatch(name: "border.hairline", color: Color.ds.border.hairline)
            }
        }
    }

    // MARK: - Typography

    private var typographySection: some View {
        SectionContainer(title: "Font.ds") {
            VStack(alignment: .leading, spacing: DSSpacing.m) {
                TypographySample(name: "hero", family: "Nunito-ExtraBold", size: 48, font: .ds.hero)
                TypographySample(name: "largeTitle", family: "Nunito-Bold", size: 36, font: .ds.largeTitle)
                TypographySample(name: "title", family: "Nunito-Bold", size: 28, font: .ds.title)
                TypographySample(name: "headline", family: "Inter-SemiBold", size: 22, font: .ds.headline)
                TypographySample(name: "body", family: "Inter-Regular", size: 18, font: .ds.body)
                TypographySample(name: "caption", family: "Inter-Regular", size: 15, font: .ds.caption)
            }
        }
    }

    // MARK: - Spacing

    private var spacingSection: some View {
        SectionContainer(title: "DSSpacing") {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                SpacingBar(name: "xxs", value: DSSpacing.xxs)
                SpacingBar(name: "xs", value: DSSpacing.xs)
                SpacingBar(name: "s", value: DSSpacing.s)
                SpacingBar(name: "m", value: DSSpacing.m)
                SpacingBar(name: "l", value: DSSpacing.l)
                SpacingBar(name: "xl", value: DSSpacing.xl)
                SpacingBar(name: "xxl", value: DSSpacing.xxl)
                SpacingBar(name: "xxxl", value: DSSpacing.xxxl)
            }
        }
    }

    // MARK: - Radius

    private var radiusSection: some View {
        SectionContainer(title: "DSRadius") {
            HStack(spacing: DSSpacing.l) {
                RadiusSample(name: "s", radius: DSRadius.s)
                RadiusSample(name: "m", radius: DSRadius.m)
                RadiusSample(name: "l", radius: DSRadius.l)
                RadiusSample(name: "xl", radius: DSRadius.xl)
            }
        }
    }

    // MARK: - Size

    private var sizeSection: some View {
        SectionContainer(title: "DSSize") {
            VStack(alignment: .leading, spacing: DSSpacing.l) {
                VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                    RoundedRectangle(cornerRadius: DSRadius.s)
                        .fill(Color.ds.background.elevated)
                        .overlay(RoundedRectangle(cornerRadius: DSRadius.s).stroke(Color.ds.border.hairline))
                        .frame(width: DSSize.channelCardWidth, height: DSSize.channelCardHeight)
                    TokenCaption("channelCardWidth = \(Int(DSSize.channelCardWidth)), channelCardHeight = \(Int(DSSize.channelCardHeight))")
                }

                VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                    RoundedRectangle(cornerRadius: DSRadius.s)
                        .fill(Color.ds.background.elevated)
                        .overlay(RoundedRectangle(cornerRadius: DSRadius.s).stroke(Color.ds.border.hairline))
                        .frame(maxWidth: DSSize.sheetMaxWidth)
                        .frame(height: 60)
                    TokenCaption("sheetMaxWidth = \(Int(DSSize.sheetMaxWidth))")
                }

                VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                    ZStack {
                        DSGradient.dark
                        Text("Playlist Gate")
                            .font(.ds.title)
                            .foregroundStyle(Color.ds.text.primary)
                    }
                    .frame(height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: DSRadius.s))
                    .blur(radius: DSSize.gateBlurRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: DSRadius.s)
                            .fill(Color.ds.background.overlay)
                    )
                    TokenCaption("gateBlurRadius = \(Int(DSSize.gateBlurRadius)) — content blurred, then Color.ds.background.overlay on top, as in RootView")
                }
            }
        }
    }

    // MARK: - Shadow

    private var shadowSection: some View {
        SectionContainer(title: "DSShadow") {
            HStack(alignment: .top, spacing: DSSpacing.xxl) {
                ShadowSample(name: "card", style: DSShadow.card)
                ShadowSample(name: "hero", style: DSShadow.hero)
                ShadowSample(name: "floating", style: DSShadow.floating)
                VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                    RoundedRectangle(cornerRadius: DSRadius.s)
                        .fill(Color.ds.background.elevated)
                        .frame(width: 140, height: 90)
                    TokenCaption("focusGlow — see Focus\nsection below for live demo")
                }
            }
        }
    }

    // MARK: - Animation

    private var animationSection: some View {
        SectionContainer(title: "DSAnimation") {
            HStack(spacing: DSSpacing.xxl) {
                AnimationDemo(name: "fast (0.25s)", animation: DSAnimation.fast)
                AnimationDemo(name: "normal (0.35s)", animation: DSAnimation.normal)
                AnimationDemo(name: "slow (0.6s)", animation: DSAnimation.slow)
            }
        }
    }

    // MARK: - Gradient

    private var gradientSection: some View {
        SectionContainer(title: "DSGradient") {
            HStack(spacing: DSSpacing.l) {
                GradientSample(name: "love", gradient: DSGradient.love)
                GradientSample(name: "dark", gradient: DSGradient.dark)
                GradientSample(name: "glow", gradient: DSGradient.glow)
            }
        }
    }

    // MARK: - Focus (.dsFocusable / .dsSelected)

    private var focusSection: some View {
        SectionContainer(title: ".dsFocusable() / .dsSelected()") {
            VStack(alignment: .leading, spacing: DSSpacing.l) {
                HStack(spacing: DSSpacing.xxl) {
                    FocusDemoTile(name: "card (1.08)", scale: DSFocusScale.card)
                    FocusDemoTile(name: "button (1.06)", scale: DSFocusScale.button)
                    FocusDemoTile(name: "chip (1.05)", scale: DSFocusScale.chip)
                }
                TokenCaption("Move focus onto a tile with the remote/arrow keys to see the ring + glow + scale.")
                SelectedDemoTile()
            }
        }
    }

    // MARK: - Buttons (DSButton)

    private var buttonSection: some View {
        SectionContainer(title: "DSButtonStyle") {
            VStack(alignment: .leading, spacing: DSSpacing.m) {
                HStack(spacing: DSSpacing.s) {
                    Button("Primary") {}
                        .buttonStyle(DSButtonStyle(variant: .primary))
                    Button("Secondary") {}
                        .buttonStyle(DSButtonStyle(variant: .secondary))
                    Button("Outline") {}
                        .buttonStyle(DSButtonStyle(variant: .outline))
                    Button("Ghost") {}
                        .buttonStyle(DSButtonStyle(variant: .ghost))
                    Button {
                    } label: {
                        Image(systemName: "heart")
                    }
                    .buttonStyle(DSButtonStyle(variant: .icon))
                }
                HStack(spacing: DSSpacing.s) {
                    Button("Loading") {}
                        .buttonStyle(DSButtonStyle(variant: .primary, isLoading: true))
                    Button("Disabled") {}
                        .buttonStyle(DSButtonStyle(variant: .primary))
                        .disabled(true)
                }
                TokenCaption("Icon button is visually 44×44 with a 100×100 focus/hit area (Open Question 6).")
            }
        }
    }

    // MARK: - TextFields (DSTextField)

    private var textFieldSection: some View {
        SectionContainer(title: "DSTextField") {
            TextFieldDemo()
        }
    }

    // MARK: - Cards (DSCardStyle)

    private var cardSection: some View {
        SectionContainer(title: "DSCardStyle") {
            CardStyleDemoTile()
        }
    }

    // MARK: - Badges (DSBadge)

    private var badgeSection: some View {
        SectionContainer(title: "DSBadge") {
            HStack(spacing: DSSpacing.s) {
                DSBadge(style: .live)
                DSBadge(style: .new)
                DSBadge(style: .hd)
                DSBadge(style: .fourK)
                DSBadge(style: .premium)
                DSBadge(style: .adult)
                DSBadge(style: .rec)
            }
        }
    }
}

// MARK: - Shared building blocks

/// Mirrors the mockup's own section-card chrome (`background:#171723;
/// border:1px solid rgba(255,255,255,.08); border-radius:24px; padding:32px`)
/// — `Color.ds.background.surface` / `Color.ds.border.hairline` / `DSRadius.l`
/// / `DSSpacing.xl` all already match these values exactly, no new tokens
/// needed. Without this card, every section (not just inputs) sits directly on
/// the screen's `Color.ds.background.primary` with nothing to visually group
/// it — `DSTextField` in particular relies on a lighter container behind it to
/// read as embedded rather than floating on bare page background, since its
/// own fill is transparent (see DSTextField.swift).
private struct SectionContainer<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.m) {
            Text(title)
                .font(.ds.headline)
                .foregroundStyle(Color.ds.text.primary)
            content
        }
        .padding(DSSpacing.xl)
        .background(Color.ds.background.surface, in: RoundedRectangle(cornerRadius: DSRadius.l))
        .overlay {
            RoundedRectangle(cornerRadius: DSRadius.l)
                .stroke(Color.ds.border.hairline, lineWidth: 1)
        }
    }
}

private struct TokenCaption: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.ds.caption)
            .foregroundStyle(Color.ds.text.secondary)
    }
}

private struct ColorSwatch: View {
    let name: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xxs) {
            RoundedRectangle(cornerRadius: DSRadius.s)
                .fill(color)
                .overlay(RoundedRectangle(cornerRadius: DSRadius.s).stroke(Color.white.opacity(0.15)))
                .frame(height: 64)
            TokenCaption(name)
        }
    }
}

private struct TypographySample: View {
    let name: String
    let family: String
    let size: Int
    let font: Font

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xxs) {
            Text("The quick fox — Быстрая лиса 123")
                .font(font)
                .foregroundStyle(Color.ds.text.primary)
            TokenCaption("\(name) — \(family) \(size)pt")
        }
    }
}

private struct SpacingBar: View {
    let name: String
    let value: CGFloat

    var body: some View {
        HStack(spacing: DSSpacing.s) {
            TokenCaption("\(name) = \(Int(value))")
                .frame(width: 90, alignment: .leading)
            RoundedRectangle(cornerRadius: DSRadius.s / 4)
                .fill(Color.ds.accent.info)
                .frame(width: value * 4, height: 20)
        }
    }
}

private struct RadiusSample: View {
    let name: String
    let radius: CGFloat

    var body: some View {
        VStack(spacing: DSSpacing.xxs) {
            RoundedRectangle(cornerRadius: radius)
                .fill(Color.ds.background.elevated)
                .overlay(RoundedRectangle(cornerRadius: radius).stroke(Color.ds.border.hairline))
                .frame(width: 120, height: 80)
            TokenCaption("\(name) = \(Int(radius))")
        }
    }
}

private struct ShadowSample: View {
    let name: String
    let style: DSShadowStyle

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xxs) {
            RoundedRectangle(cornerRadius: DSRadius.s)
                .fill(Color.ds.background.elevated)
                .frame(width: 140, height: 90)
                .shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
            TokenCaption("\(name) — r\(Int(style.radius)) x\(Int(style.x)) y\(Int(style.y))")
        }
        .padding(.bottom, DSSpacing.s) // room for the shadow itself to render, not clipped by the section
    }
}

private struct AnimationDemo: View {
    let name: String
    let animation: Animation
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: DSSpacing.xs) {
            RoundedRectangle(cornerRadius: DSRadius.s)
                .fill(Color.ds.accent.info)
                .frame(width: isExpanded ? 140 : 90, height: 60)

            Button("Toggle") {
                withAnimation(animation) { isExpanded.toggle() }
            }
            TokenCaption(name)
        }
    }
}

private struct GradientSample: View {
    let name: String
    let gradient: LinearGradient

    var body: some View {
        VStack(spacing: DSSpacing.xxs) {
            RoundedRectangle(cornerRadius: DSRadius.s)
                .fill(gradient)
                .frame(width: 160, height: 90)
            TokenCaption(name)
        }
    }
}

private struct FocusDemoTile: View {
    let name: String
    let scale: CGFloat
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: DSSpacing.xs) {
            RoundedRectangle(cornerRadius: DSRadius.s)
                .fill(Color.ds.background.elevated)
                .frame(width: 120, height: 80)
                .focusable()
                .focused($isFocused)
                .dsFocusable(isFocused, scale: scale)
            TokenCaption(name)
        }
        .padding(DSSpacing.s) // room for the scale/glow to render without clipping neighbors
    }
}

private struct SelectedDemoTile: View {
    @State private var isSelected = false

    var body: some View {
        HStack(spacing: DSSpacing.m) {
            RoundedRectangle(cornerRadius: DSRadius.s)
                .fill(Color.ds.background.elevated)
                .frame(width: 120, height: 80)
                .dsSelected(isSelected)

            Button(isSelected ? "Deselect" : "Select") {
                isSelected.toggle()
            }
            .buttonStyle(DSButtonStyle(variant: .secondary))
        }
        .padding(.trailing, DSSpacing.s)
    }
}

private struct TextFieldDemo: View {
    @State private var plainText = ""
    @State private var searchText = ""
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case plain, search
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.s) {
            DSTextField(placeholder: "Введите текст...", text: $plainText, isFocused: focusedField == .plain)
                .focused($focusedField, equals: .plain)
                .frame(maxWidth: 420)

            DSTextField(variant: .search, placeholder: "Поиск каналов, фильмов...", text: $searchText, isFocused: focusedField == .search)
                .focused($focusedField, equals: .search)
                .frame(maxWidth: 420)

            TokenCaption("Focus a field to see the .input focus preset (single #B85CFF border + soft glow, no scale).")
        }
    }
}

private struct CardStyleDemoTile: View {
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xs) {
            RoundedRectangle(cornerRadius: DSRadius.s)
                .fill(Color.ds.background.elevated)
                .frame(width: DSSize.channelCardWidth, height: DSSize.channelCardHeight)
                .focusable()
                .focused($isFocused)
                .dsCardStyle(isFocused: isFocused)
            TokenCaption("Same chrome ChannelCardView uses — hairline border + DSShadow.card + .dsFocusable(scale: .card).")
        }
        .padding(DSSpacing.s)
    }
}

#if DEBUG
#Preview {
    DesignSystemShowcaseView()
}
#endif
