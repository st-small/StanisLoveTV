import Dependencies
import Foundation
import SQLiteData
import Testing
@testable import StanisLoveTV

private func makeTestDatabase() throws -> DatabaseStack {
    let queue = try DatabaseQueue()
    var migrator = DatabaseMigrator()
    Migrations.register(in: &migrator)
    try migrator.migrate(queue)
    return DatabaseStack(writer: queue)
}

private func makeTestUserDefaultsClient() -> UserDefaultsClient {
    nonisolated(unsafe) let defaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
    return UserDefaultsClient(
        data: { defaults.data(forKey: $0) },
        setData: { value, key in defaults.set(value, forKey: key) },
        stringArray: { defaults.stringArray(forKey: $0) },
        setStringArray: { value, key in defaults.set(value, forKey: key) }
    )
}

@Suite("DefaultChannelRepository")
struct DefaultChannelRepositoryTests {

    @Test("fetchAll_resolvesIsFavoriteViaTvgID")
    func fetchAllResolvesIsFavoriteViaTvgID() async throws {
        let db = try makeTestDatabase()
        let playlistID = UUID()
        let channel = Channel.mock(tvgID: "bbc1")

        try await withDependencies {
            $0.database = db
            $0.userDefaultsClient = makeTestUserDefaultsClient()
            $0.favoriteRepository = await DefaultFavoriteRepository()
        } operation: {
            // Resolve the same DI-provided favoriteRepository instance
            // DefaultChannelRepository itself reads, rather than a second actor —
            // the repository caches decoded state per instance.
            @Dependency(\.favoriteRepository) var favoriteRepo

            try await DefaultChannelRepository().save([channel], playlistID: playlistID)
            _ = try await favoriteRepo.toggle(favoriteKey: "bbc1")

            let fetched = try await DefaultChannelRepository().fetchAll(playlistID: playlistID)
            #expect(fetched.first?.isFavorite == true)
        }
    }

    @Test("fetchAll_resolvesIsFavoriteViaStreamURLFallbackWhenTvgIDNil")
    func fetchAllResolvesIsFavoriteViaStreamURLFallbackWhenTvgIDNil() async throws {
        let db = try makeTestDatabase()
        let playlistID = UUID()
        let streamURL = URL(string: "https://example.com/no-tvgid.m3u8")!
        let channel = Channel.mock(streamURL: streamURL, tvgID: nil)

        try await withDependencies {
            $0.database = db
            $0.userDefaultsClient = makeTestUserDefaultsClient()
            $0.favoriteRepository = await DefaultFavoriteRepository()
        } operation: {
            @Dependency(\.favoriteRepository) var favoriteRepo

            try await DefaultChannelRepository().save([channel], playlistID: playlistID)
            _ = try await favoriteRepo.toggle(favoriteKey: streamURL.absoluteString)

            let fetched = try await DefaultChannelRepository().fetchAll(playlistID: playlistID)
            #expect(fetched.first?.isFavorite == true)
        }
    }

    @Test("deleteAll_removesChannelsForPlaylist_leavesOthersUntouched")
    func deleteAllRemovesChannelsForPlaylistLeavesOthersUntouched() async throws {
        let db = try makeTestDatabase()
        let playlistA = UUID()
        let playlistB = UUID()

        try await withDependencies {
            $0.database = db
            $0.userDefaultsClient = makeTestUserDefaultsClient()
            $0.favoriteRepository = await DefaultFavoriteRepository()
        } operation: {
            let repo = DefaultChannelRepository()
            try await repo.save([Channel.mock(name: "A1")], playlistID: playlistA)
            try await repo.save([Channel.mock(name: "B1")], playlistID: playlistB)

            try await repo.deleteAll(playlistID: playlistA)

            let remainingA = try await repo.fetchAll(playlistID: playlistA)
            let remainingB = try await repo.fetchAll(playlistID: playlistB)
            #expect(remainingA.isEmpty)
            #expect(remainingB.count == 1)
        }
    }

    @Test("fetchFavorites_mergesAcrossPlaylists")
    func fetchFavoritesMergesAcrossPlaylists() async throws {
        let db = try makeTestDatabase()
        let playlistA = UUID()
        let playlistB = UUID()
        let favoriteInA = Channel.mock(name: "Fav A", tvgID: "fav-a")
        let favoriteInB = Channel.mock(name: "Fav B", tvgID: "fav-b")
        let notFavorite = Channel.mock(name: "Not Fav", tvgID: "not-fav")

        try await withDependencies {
            $0.database = db
            $0.userDefaultsClient = makeTestUserDefaultsClient()
            $0.favoriteRepository = await DefaultFavoriteRepository()
        } operation: {
            @Dependency(\.favoriteRepository) var favoriteRepo

            let channelRepo = DefaultChannelRepository()
            try await channelRepo.save([favoriteInA, notFavorite], playlistID: playlistA)
            try await channelRepo.save([favoriteInB], playlistID: playlistB)

            _ = try await favoriteRepo.toggle(favoriteKey: "fav-a")
            _ = try await favoriteRepo.toggle(favoriteKey: "fav-b")

            let favorites = try await channelRepo.fetchFavorites()
            #expect(favorites.count == 2)
            let allFavorites = favorites.allSatisfy(\.isFavorite)
            #expect(allFavorites)
            #expect(Set(favorites.map(\.name)) == ["Fav A", "Fav B"])
        }
    }

    @Test("search_resolvesIsFavorite")
    func searchResolvesIsFavorite() async throws {
        let db = try makeTestDatabase()
        let playlistID = UUID()
        let channel = Channel.mock(name: "Sport News", groupTitle: "Sports", tvgID: "sport1")

        try await withDependencies {
            $0.database = db
            $0.userDefaultsClient = makeTestUserDefaultsClient()
            $0.favoriteRepository = await DefaultFavoriteRepository()
        } operation: {
            @Dependency(\.favoriteRepository) var favoriteRepo

            try await DefaultChannelRepository().save([channel], playlistID: playlistID)
            _ = try await favoriteRepo.toggle(favoriteKey: "sport1")

            let results = try await DefaultChannelRepository().search(query: "sport", playlistID: playlistID)
            #expect(results.first?.isFavorite == true)
        }
    }
}
