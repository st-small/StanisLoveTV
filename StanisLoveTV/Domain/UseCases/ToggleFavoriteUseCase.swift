import Dependencies
import Foundation

struct ToggleFavoriteUseCase {
    var execute: (Channel) async throws -> Bool
}

extension ToggleFavoriteUseCase: DependencyKey {
    static var liveValue: Self {
        .init { channel in
            @Dependency(\.favoriteRepository) var repo
            return try await repo.toggle(favoriteKey: channel.favoriteKey)
        }
    }

    static let testValue = ToggleFavoriteUseCase(
        execute: { _ in unimplemented("ToggleFavoriteUseCase.execute", placeholder: false) }
    )
}
