import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        MainTabView(appState: appState)
    }
}

enum AppTab: Hashable {
    case channels, guide, playlists, settings
}

// Separate view so @State can be initialized with injected AppState
private struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab: AppTab = .channels
    @State private var playlistsViewModel: PlaylistsViewModel
    @State private var channelListViewModel: ChannelListViewModel

    init(appState: AppState) {
        _playlistsViewModel = State(wrappedValue: PlaylistsViewModel(appState: appState))
        _channelListViewModel = State(wrappedValue: ChannelListViewModel(appState: appState))
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            ChannelListView(
                viewModel: channelListViewModel,
                onNavigateToPlaylists: { selectedTab = .playlists }
            )
            .tabItem { Label("Channels", systemImage: "play.tv") }
            .tag(AppTab.channels)

            EPGView()
                .tabItem { Label("Guide", systemImage: "calendar") }
                .tag(AppTab.guide)

            PlaylistsView(viewModel: playlistsViewModel)
                .tabItem { Label("Playlists", systemImage: "list.bullet") }
                .tag(AppTab.playlists)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
                .tag(AppTab.settings)
        }
        .task(id: appState.activePlaylistID) { await channelListViewModel.load() }
        .task { await playlistsViewModel.load() }
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            await playlistsViewModel.refreshActivePlaylistIfNeeded()
        }
    }
}
