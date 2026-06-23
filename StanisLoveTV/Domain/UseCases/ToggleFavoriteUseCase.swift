import Dependencies
import Foundation

struct ToggleFavoriteUseCase {
    var execute: (UUID) async throws -> Bool
}

extension ToggleFavoriteUseCase: DependencyKey {
    static var liveValue: Self {
        .init { channelID in
            @Dependency(\.favoriteRepository) var repo
            return try await repo.toggle(channelID: channelID)
        }
    }

    static let testValue = ToggleFavoriteUseCase(
        execute: { _ in unimplemented("ToggleFavoriteUseCase.execute", placeholder: false) }
    )
}
