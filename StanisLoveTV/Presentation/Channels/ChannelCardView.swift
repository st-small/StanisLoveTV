import Kingfisher
import SwiftUI

struct ChannelCardView: View {
    let channel: Channel
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            KFImage(channel.logoURL)
                .placeholder {
                    Image(systemName: "tv")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                }
                .resizable()
                .scaledToFit()
                .accessibilityHidden(true)
                .frame(maxWidth: .infinity)
                .frame(height: TVSize.channelCardHeight * 0.65)
                .background(.ultraThinMaterial)

            VStack(alignment: .leading, spacing: Spacing.xs / 2) {
                Text(channel.name)
                    .font(.headline)
                    .lineLimit(1)

                Text(channel.groupTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .frame(height: TVSize.channelCardHeight * 0.35)
        }
        .frame(width: TVSize.channelCardWidth, height: TVSize.channelCardHeight)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: TVSize.thumbnailCornerRadius))
        .focusable()
        .focused($isFocused)
        .scaleEffect(isFocused ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isFocused)
        .accessibilityLabel("\(channel.name), \(channel.groupTitle)")
        .accessibilityHint("Press to play")
        .accessibilityAddTraits(.isButton)
    }
}
