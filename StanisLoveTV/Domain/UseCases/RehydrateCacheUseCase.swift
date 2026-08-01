import Dependencies
import Foundation

/// Refetches and re-parses channels for any playlist whose SQLite cache is empty —
/// e.g. after tvOS purges `Library/Caches` under storage pressure. Playlists
/// themselves live in `UserDefaults` and survive that purge, so this rebuilds the
/// derived data rather than restoring anything the user entered.
nonisolated struct RehydrateCacheUseCase {
    var execute: () async throws -> Void
}

nonisolated extension RehydrateCacheUseCase: DependencyKey {
    static var liveValue: Self {
        .init {
            @Dependency(\.playlistRepository) var playlistRepo
            @Dependency(\.channelRepository) var channelRepo
            @Dependency(\.refreshPlaylistUseCase) var refreshPlaylist

            let playlists = try await playlistRepo.fetchAll()
            for playlist in playlists {
                let existing = try await channelRepo.fetchAll(playlistID: playlist.id)
                guard existing.isEmpty else { continue }
                // Best-effort: one playlist unreachable (e.g. offline) shouldn't block
                // rehydrating the rest.
                try? await refreshPlaylist.execute(playlist.id)
            }
        }
    }

    static let testValue = RehydrateCacheUseCase(
        execute: { unimplemented("RehydrateCacheUseCase.execute") }
    )
}
