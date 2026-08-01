import Dependencies
import Foundation

nonisolated struct SearchChannelsUseCase {
    var execute: (String, UUID) async throws -> [Channel]
}

nonisolated extension SearchChannelsUseCase: DependencyKey {
    static var liveValue: Self {
        .init { query, playlistID in
            @Dependency(\.channelRepository) var repo
            return try await repo.search(query: query, playlistID: playlistID)
        }
    }

    static let testValue = SearchChannelsUseCase(
        execute: { _, _ in unimplemented("SearchChannelsUseCase.execute", placeholder: []) }
    )
}
