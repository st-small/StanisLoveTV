import Dependencies
import Foundation
import Observation

@MainActor
@Observable
final class PlaylistsViewModel {
    var playlists: [Playlist] = []
    var isLoading = false
    var error: AppError?
    var showAddSheet = false

    var activePlaylistID: UUID? { appState.activePlaylistID }

    @ObservationIgnored private let appState: AppState
    @ObservationIgnored @Dependency(\.fetchPlaylistsUseCase) private var fetchPlaylists
    @ObservationIgnored @Dependency(\.addPlaylistUseCase) private var addPlaylist
    @ObservationIgnored @Dependency(\.deletePlaylistUseCase) private var deletePlaylist
    @ObservationIgnored @Dependency(\.refreshPlaylistUseCase) private var refreshPlaylist

    init(appState: AppState) {
        self.appState = appState
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            playlists = try await fetchPlaylists.execute()
        } catch {
            self.error = AppError(error)
        }
    }

    func add(url: URL, name: String, epgURL: URL?) async throws {
        isLoading = true
        defer { isLoading = false }
        let playlist = Playlist(
            id: UUID(),
            name: name,
            url: url,
            type: .m3u,
            epgURL: epgURL,
            lastUpdated: nil
        )
        try await addPlaylist.execute(playlist)
        playlists = try await fetchPlaylists.execute()
        if appState.activePlaylistID == nil {
            appState.activePlaylistID = playlist.id
        }
    }

    func delete(id: UUID) async {
        do {
            try await deletePlaylist.execute(id)
            playlists = playlists.filter { $0.id != id }
            if appState.activePlaylistID == id {
                appState.activePlaylistID = playlists.first?.id
            }
        } catch {
            self.error = AppError(error)
        }
    }

    func refresh(id: UUID) async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            try await refreshPlaylist.execute(id)
            playlists = try await fetchPlaylists.execute()
        } catch {
            self.error = AppError(error)
        }
    }

    func refreshActivePlaylistIfNeeded() async {
        guard let id = appState.activePlaylistID else { return }
        guard let playlist = playlists.first(where: { $0.id == id }) else { return }
        if let lastFetched = playlist.lastUpdated,
           Date().timeIntervalSince(lastFetched) <= AppConstants.playlistRefreshInterval {
            return
        }
        await refresh(id: id)
    }
}
