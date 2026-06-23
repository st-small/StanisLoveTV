import Dependencies
import Foundation

struct AddPlaylistUseCase {
    var execute: (Playlist) async throws -> Void
}

extension AddPlaylistUseCase: DependencyKey {
    static var liveValue: Self {
        .init { playlist in
            @Dependency(\.playlistRepository) var repo
            try await repo.insert(playlist)
        }
    }

    static let testValue = AddPlaylistUseCase(
        execute: { _ in unimplemented("AddPlaylistUseCase.execute") }
    )
}
