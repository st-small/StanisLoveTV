import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppStateController.self) private var appStateController

    var body: some View {
        Group {
            switch appStateController.phase {
            case .splash:
                SplashView()
                    .transition(.opacity)
            case .ready:
                MainTabView(appState: appState)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: appStateController.phase)
        .task { await appStateController.start() }
    }
}

enum AppTab: Hashable {
    case channels, guide, playlists, settings
}

// Separate view so @State can be initialized with injected AppState
private struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppStateController.self) private var appStateController
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab: AppTab = .channels
    @State private var playlistsViewModel: PlaylistsViewModel
    @State private var channelListViewModel: ChannelListViewModel

    init(appState: AppState) {
        _playlistsViewModel = State(wrappedValue: PlaylistsViewModel(appState: appState))
        _channelListViewModel = State(wrappedValue: ChannelListViewModel(appState: appState))
    }

    var body: some View {
        ZStack {
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
            .task {
                await playlistsViewModel.load()
                await playlistsViewModel.rehydrateCacheIfNeeded()
            }
            .task(id: scenePhase) {
                guard scenePhase == .active else { return }
                await playlistsViewModel.refreshActivePlaylistIfNeeded()
            }
            .onChange(of: appState.isRehydratingCache) { wasRehydrating, isRehydrating in
                guard wasRehydrating, !isRehydrating else { return }
                Task { await channelListViewModel.load() }
            }
            .blur(radius: appStateController.playlistGateState == .locked ? DSSize.gateBlurRadius : 0)
            .disabled(appStateController.playlistGateState == .locked)

            if appStateController.playlistGateState == .locked {
                PlaylistGateOverlayView(onAdd: { url, name, epgURL in
                    try await playlistsViewModel.add(url: url, name: name, epgURL: epgURL)
                    appStateController.unlockGate()
                })
                .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: appStateController.playlistGateState)
    }
}
