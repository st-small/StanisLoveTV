import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        TabView {
            ChannelListView()
                .tabItem { Label("Channels", systemImage: "play.tv") }

            EPGView()
                .tabItem { Label("Guide", systemImage: "calendar") }

            PlaylistsView()
                .tabItem { Label("Playlists", systemImage: "list.bullet") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
    }
}
