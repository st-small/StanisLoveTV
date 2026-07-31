import Dependencies
import Foundation
import Testing
@testable import StanisLoveTV

private func makeTestUserDefaultsClient() -> UserDefaultsClient {
    let defaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
    return UserDefaultsClient(
        data: { defaults.data(forKey: $0) },
        setData: { value, key in defaults.set(value, forKey: key) },
        stringArray: { defaults.stringArray(forKey: $0) },
        setStringArray: { value, key in defaults.set(value, forKey: key) }
    )
}

@Suite("DefaultFavoriteRepository")
struct DefaultFavoriteRepositoryTests {

    @Test("toggle_unfavorited_addsKey")
    func toggleUnfavoritedAddsKey() async throws {
        let testDefaults = makeTestUserDefaultsClient()

        try await withDependencies {
            $0.userDefaultsClient = testDefaults
        } operation: {
            let repo = DefaultFavoriteRepository()
            let isNowFavorite = try await repo.toggle(favoriteKey: "bbc1")
            #expect(isNowFavorite == true)
            let all = try await repo.fetchAll()
            #expect(all == ["bbc1"])
        }
    }

    @Test("toggle_favorited_removesKey")
    func toggleFavoritedRemovesKey() async throws {
        let testDefaults = makeTestUserDefaultsClient()

        try await withDependencies {
            $0.userDefaultsClient = testDefaults
        } operation: {
            let repo = DefaultFavoriteRepository()
            _ = try await repo.toggle(favoriteKey: "bbc1")
            let isNowFavorite = try await repo.toggle(favoriteKey: "bbc1")
            #expect(isNowFavorite == false)
            let all = try await repo.fetchAll()
            #expect(all.isEmpty)
        }
    }

    @Test("fetchAll_returnsStoredKeys")
    func fetchAllReturnsStoredKeys() async throws {
        let testDefaults = makeTestUserDefaultsClient()

        try await withDependencies {
            $0.userDefaultsClient = testDefaults
        } operation: {
            let repo = DefaultFavoriteRepository()
            _ = try await repo.toggle(favoriteKey: "bbc1")
            _ = try await repo.toggle(favoriteKey: "cnn")
            let all = try await repo.fetchAll()
            #expect(all == ["bbc1", "cnn"])
        }
    }

    @Test("concurrentToggles_serializedCorrectly")
    func concurrentTogglesSerializedCorrectly() async throws {
        let testDefaults = makeTestUserDefaultsClient()
        let keys = (0..<20).map { "channel-\($0)" }

        try await withDependencies {
            $0.userDefaultsClient = testDefaults
        } operation: {
            let repo = DefaultFavoriteRepository()
            try await withThrowingTaskGroup(of: Void.self) { group in
                for key in keys {
                    group.addTask { _ = try await repo.toggle(favoriteKey: key) }
                }
                try await group.waitForAll()
            }
            let all = try await repo.fetchAll()
            #expect(all == Set(keys))
        }
    }
}
