import Dependencies
import Foundation

nonisolated struct FetchPlaylistsUseCase {
    var execute: () async throws -> [Playlist]
}

nonisolated extension FetchPlaylistsUseCase: DependencyKey {
    static var liveValue: Self {
        .init {
            @Dependency(\.playlistRepository) var repo
            return try await repo.fetchAll()
        }
    }

    static let testValue = FetchPlaylistsUseCase(
        execute: { unimplemented("FetchPlaylistsUseCase.execute", placeholder: []) }
    )
}
