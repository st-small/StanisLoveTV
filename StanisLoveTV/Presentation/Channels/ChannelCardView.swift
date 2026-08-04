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
                .frame(height: DSSize.channelCardHeight * 0.65)
                .background(.ultraThinMaterial)

            VStack(alignment: .leading, spacing: DSSpacing.xs / 2) {
                Text(channel.name)
                    .font(.headline)
                    .lineLimit(1)

                Text(channel.groupTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DSSpacing.s)
            .padding(.vertical, DSSpacing.xs)
            .frame(height: DSSize.channelCardHeight * 0.35)
        }
        .frame(width: DSSize.channelCardWidth, height: DSSize.channelCardHeight)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: DSRadius.s))
        .focusable()
        .focused($isFocused)
        .scaleEffect(isFocused ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isFocused)
        .accessibilityLabel("\(channel.name), \(channel.groupTitle)")
        .accessibilityHint("Press to play")
        .accessibilityAddTraits(.isButton)
    }
}
