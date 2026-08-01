import Dependencies
import Foundation

nonisolated struct FetchChannelsUseCase {
    var execute: (UUID) async throws -> [Channel]
}

nonisolated extension FetchChannelsUseCase: DependencyKey {
    static var liveValue: Self {
        .init { playlistID in
            @Dependency(\.channelRepository) var repo
            return try await repo.fetchAll(playlistID: playlistID)
        }
    }

    static let testValue = FetchChannelsUseCase(
        execute: { _ in unimplemented("FetchChannelsUseCase.execute", placeholder: []) }
    )
}
