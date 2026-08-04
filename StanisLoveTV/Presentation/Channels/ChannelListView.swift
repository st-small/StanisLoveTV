import SwiftUI

struct ChannelListView: View {
    @Bindable var viewModel: ChannelListViewModel
    var onNavigateToPlaylists: () -> Void = {}

    @FocusState private var isSearchFocused: Bool

    private let gridColumns = [
        GridItem(.adaptive(minimum: DSSize.channelCardWidth), spacing: DSSpacing.l)
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
            PlayerView(channel: channel, onDismiss: { viewModel.selectedChannel = nil })
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
        DSTextField(variant: .search, placeholder: "Search channels...", text: $viewModel.searchQuery, isFocused: isSearchFocused)
            .focused($isSearchFocused)
            .padding(DSSpacing.s)
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
                    LazyVGrid(columns: gridColumns, spacing: DSSpacing.l) {
                        ForEach(viewModel.filteredChannels) { channel in
                            ChannelCardView(channel: channel)
                                .onTapGesture { viewModel.selectedChannel = channel }
                        }
                    }
                    .padding(DSSpacing.l)
                }
                .focusSection()
            }
        }
    }

    @ViewBuilder
    private var emptyStateView: some View {
        if viewModel.hasActivePlaylists && viewModel.isRestoringCache {
            ContentUnavailableView {
                Label("Restoring Your Channels", systemImage: "arrow.triangle.2.circlepath")
            } description: {
                Text("Re-downloading your playlist in the background.")
            }
            .accessibilityLabel("Restoring your channels from your saved playlist")
        } else if viewModel.hasActivePlaylists {
            ContentUnavailableView(
                "No Channels",
                systemImage: "tv.slash",
                description: Text("No channels found. Try refreshing the playlist in Settings.")
            )
        } else {
            ContentUnavailableView {
                Label("No Playlists", systemImage: "list.bullet.rectangle")
            } description: {
                Text("Add a playlist to get started.")
            } actions: {
                Button("Go to Playlists", action: onNavigateToPlaylists)
                    .accessibilityHint("Opens the Playlists tab")
            }
        }
    }
}
