import Dependencies
import Foundation

nonisolated struct FetchEPGUseCase {
    var execute: (String, Date) async throws -> [EPGProgram]
}

nonisolated extension FetchEPGUseCase: DependencyKey {
    static var liveValue: Self {
        .init { channelID, after in
            @Dependency(\.epgRepository) var repo
            return try await repo.fetchPrograms(channelID: channelID, after: after)
        }
    }

    static let testValue = FetchEPGUseCase(
        execute: { _, _ in unimplemented("FetchEPGUseCase.execute", placeholder: []) }
    )
}
