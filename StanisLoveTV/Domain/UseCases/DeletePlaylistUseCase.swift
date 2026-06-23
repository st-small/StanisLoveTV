import Dependencies
import Foundation

struct DeletePlaylistUseCase {
    var execute: (UUID) async throws -> Void
}

extension DeletePlaylistUseCase: DependencyKey {
    static var liveValue: Self {
        .init { id in
            @Dependency(\.playlistRepository) var repo
            try await repo.delete(id: id)
        }
    }

    static let testValue = DeletePlaylistUseCase(
        execute: { _ in unimplemented("DeletePlaylistUseCase.execute") }
    )
}
