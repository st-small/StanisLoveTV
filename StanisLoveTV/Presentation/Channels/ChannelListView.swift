import SwiftUI

struct ChannelListView: View {
    @Bindable var viewModel: ChannelListViewModel

    private let gridColumns = [
        GridItem(.adaptive(minimum: TVSize.channelCardWidth), spacing: Spacing.md)
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar

                if viewModel.searchQuery.trimmingCharacters(in: .whitespaces).count >= 2 {
                    ChannelSearchView(
                        results: viewModel.searchResults,
                        query: viewModel.searchQuery,
                        onSelect: { viewModel.selectedChannel = $0 }
                    )
                } else {
                    mainContent
                }
            }
            .navigationTitle("Channels")
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
        }
        .onExitCommand {
            if !viewModel.searchQuery.isEmpty {
                viewModel.searchQuery = ""
                viewModel.searchResults = []
            }
        }
        .fullScreenCover(item: $viewModel.selectedChannel) { channel in
            Text("Playing: \(channel.name)")
                .onExitCommand { viewModel.selectedChannel = nil }
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.error != nil },
            set: { _ in viewModel.error = nil }
        )) {
            Button("OK") {}
        } message: {
            Text(viewModel.error?.errorDescription ?? "An error occurred.")
        }
    }

    @ViewBuilder
    private var searchBar: some View {
        TextField("Search channels...", text: $viewModel.searchQuery)
            .padding(Spacing.sm)
            .onChange(of: viewModel.searchQuery) {
                Task { await viewModel.search() }
            }
    }

    @ViewBuilder
    private var mainContent: some View {
        if viewModel.channels.isEmpty && !viewModel.isLoading {
            emptyStateView
        } else {
            HStack(spacing: 0) {
                CategorySidebarView(
                    categories: viewModel.categories,
                    selectedCategory: $viewModel.selectedCategory
                )

                Divider()

                ScrollView {
                    LazyVGrid(columns: gridColumns, spacing: Spacing.md) {
                        ForEach(viewModel.filteredChannels) { channel in
                            ChannelCardView(channel: channel)
                                .onTapGesture { viewModel.selectedChannel = channel }
                        }
                    }
                    .padding(Spacing.md)
                }
                .focusSection()
            }
        }
    }

    @ViewBuilder
    private var emptyStateView: some View {
        if viewModel.hasActivePlaylists {
            ContentUnavailableView(
                "No Channels",
                systemImage: "tv.slash",
                description: Text("No channels found. Try refreshing the playlist in Settings.")
            )
        } else {
            ContentUnavailableView(
                "No Playlists",
                systemImage: "list.bullet.rectangle",
                description: Text("Add a playlist to get started. Go to the Playlists tab.")
            )
        }
    }
}
