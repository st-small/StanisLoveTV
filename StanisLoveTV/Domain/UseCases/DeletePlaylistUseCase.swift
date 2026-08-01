import Dependencies
import Foundation

nonisolated struct DeletePlaylistUseCase {
    var execute: (UUID) async throws -> Void
}

nonisolated extension DeletePlaylistUseCase: DependencyKey {
    static var liveValue: Self {
        .init { id in
            @Dependency(\.playlistRepository) var playlistRepo
            @Dependency(\.channelRepository) var channelRepo
            // No FK cascade since v3 (playlists moved to UserDefaults) — this is now
            // the only thing preventing orphaned channel rows. Channels are deleted
            // first: if that SQLite write fails, the playlist row (the source of
            // truth for what the UI shows and what RehydrateCacheUseCase walks)
            // is still there, so the failure is visible and retryable instead of
            // leaving orphaned rows with nothing left to clean them up.
            try await channelRepo.deleteAll(playlistID: id)
            try await playlistRepo.delete(id: id)
        }
    }

    static let testValue = DeletePlaylistUseCase(
        execute: { _ in unimplemented("DeletePlaylistUseCase.execute") }
    )
}
