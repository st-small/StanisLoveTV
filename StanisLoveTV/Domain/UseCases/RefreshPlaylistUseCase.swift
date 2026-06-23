import Dependencies
import Foundation

struct RefreshPlaylistUseCase {
    var execute: (UUID) async throws -> Void
}

extension RefreshPlaylistUseCase: DependencyKey {
    static var liveValue: Self {
        .init { playlistID in
            @Dependency(\.playlistRepository) var repo
            try await repo.updateLastFetched(id: playlistID, date: Date())
        }
    }

    static let testValue = RefreshPlaylistUseCase(
        execute: { _ in unimplemented("RefreshPlaylistUseCase.execute") }
    )
}
