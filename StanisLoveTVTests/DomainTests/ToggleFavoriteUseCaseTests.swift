import Dependencies
import Foundation
import Testing
@testable import StanisLoveTV

private func makeTestUserDefaultsClient() -> UserDefaultsClient {
    nonisolated(unsafe) let defaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
    return UserDefaultsClient(
        data: { defaults.data(forKey: $0) },
        setData: { value, key in defaults.set(value, forKey: key) },
        stringArray: { defaults.stringArray(forKey: $0) },
        setStringArray: { value, key in defaults.set(value, forKey: key) }
    )
}

@Suite("ToggleFavoriteUseCase")
struct ToggleFavoriteUseCaseTests {

    @Test("toggle_usesChannelTvgIDAsFavoriteKey")
    func toggleUsesChannelTvgIDAsFavoriteKey() async throws {
        let channel = Channel.mock(tvgID: "bbc1")

        try await withDependencies {
            $0.userDefaultsClient = makeTestUserDefaultsClient()
            $0.favoriteRepository = DefaultFavoriteRepository()
        } operation: {
            // Resolve the same DI-provided instance the use case itself reads,
            // rather than standing up a second actor — the repository caches
            // decoded state per instance, so a fresh instance would mask a
            // caching bug instead of exercising the real singleton codepath.
            @Dependency(\.favoriteRepository) var repo

            let isNowFavorite = try await ToggleFavoriteUseCase.liveValue.execute(channel)
            #expect(isNowFavorite == true)

            let stored = try await repo.fetchAll()
            #expect(stored == ["bbc1"])
        }
    }

    @Test("toggle_fallsBackToStreamURLWhenTvgIDIsNil")
    func toggleFallsBackToStreamURLWhenTvgIDIsNil() async throws {
        let streamURL = URL(string: "https://example.com/no-tvgid.m3u8")!
        let channel = Channel.mock(streamURL: streamURL, tvgID: nil)

        try await withDependencies {
            $0.userDefaultsClient = makeTestUserDefaultsClient()
            $0.favoriteRepository = DefaultFavoriteRepository()
        } operation: {
            @Dependency(\.favoriteRepository) var repo

            let isNowFavorite = try await ToggleFavoriteUseCase.liveValue.execute(channel)
            #expect(isNowFavorite == true)

            let stored = try await repo.fetchAll()
            #expect(stored == [streamURL.absoluteString])
        }
    }
}
