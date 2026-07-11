import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        MainTabView(appState: appState)
    }
}

// Separate view so @State can be initialized with injected AppState
private struct MainTabView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var playlistsViewModel: PlaylistsViewModel
    @State private var channelListViewModel: ChannelListViewModel

    init(appState: AppState) {
        _playlistsViewModel = State(wrappedValue: PlaylistsViewModel(appState: appState))
        _channelListViewModel = State(wrappedValue: ChannelListViewModel(appState: appState))
    }

    var body: some View {
        TabView {
            ChannelListView(viewModel: channelListViewModel)
                .tabItem { Label("Channels", systemImage: "play.tv") }

            EPGView()
                .tabItem { Label("Guide", systemImage: "calendar") }

            PlaylistsView(viewModel: playlistsViewModel)
                .tabItem { Label("Playlists", systemImage: "list.bullet") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
        .task { await channelListViewModel.load() }
        .task { await playlistsViewModel.load() }
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            await playlistsViewModel.refreshActivePlaylistIfNeeded()
        }
    }
}
