import Dependencies
import Foundation

struct SearchChannelsUseCase {
    var execute: (String) async throws -> [Channel]
}

extension SearchChannelsUseCase: DependencyKey {
    static var liveValue: Self {
        .init { query in
            @Dependency(\.channelRepository) var repo
            return try await repo.search(query: query)
        }
    }

    static let testValue = SearchChannelsUseCase(
        execute: { _ in unimplemented("SearchChannelsUseCase.execute", placeholder: []) }
    )
}
