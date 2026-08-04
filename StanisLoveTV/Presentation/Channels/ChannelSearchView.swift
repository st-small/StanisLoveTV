import SwiftUI

struct ChannelSearchView: View {
    let results: [Channel]
    let query: String
    let onSelect: (Channel) -> Void

    private let gridColumns = [
        GridItem(.adaptive(minimum: DSSize.channelCardWidth), spacing: DSSpacing.l)
    ]

    var body: some View {
        if results.isEmpty {
            ContentUnavailableView(
                "No Results",
                systemImage: "magnifyingglass",
                description: Text("No channels match \"\(query)\".")
            )
        } else {
            ScrollView {
                LazyVGrid(columns: gridColumns, spacing: DSSpacing.l) {
                    ForEach(results) { channel in
                        ChannelCardView(channel: channel)
                            .onTapGesture { onSelect(channel) }
                    }
                }
                .padding(DSSpacing.l)
            }
            .focusSection()
        }
    }
}
