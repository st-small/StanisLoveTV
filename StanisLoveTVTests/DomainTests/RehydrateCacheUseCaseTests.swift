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
    let defaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
    return UserDefaultsClient(
        data: { defaults.data(forKey: $0) },
        setData: { value, key in defaults.set(value, forKey: key) },
        stringArray: { defaults.stringArray(forKey: $0) },
        setStringArray: { value, key in defaults.set(value, forKey: key) }
    )
}

@Suite("RehydrateCacheUseCase")
struct RehydrateCacheUseCaseTests {

    @Test("rehydrate_refreshesPlaylistsWithZeroChannels")
    func rehydrateRefreshesPlaylistsWithZeroChannels() async throws {
        let db = try makeTestDatabase()
        let playlist = Playlist.mock()
        var refreshedIDs: [UUID] = []

        try await withDependencies {
            $0.database = db
            $0.userDefaultsClient = makeTestUserDefaultsClient()
            $0.playlistRepository = DefaultPlaylistRepository()
            $0.channelRepository = DefaultChannelRepository()
            $0.favoriteRepository = DefaultFavoriteRepository()
            $0.refreshPlaylistUseCase.execute = { id in refreshedIDs.append(id) }
        } operation: {
            try await DefaultPlaylistRepository().insert(playlist)
            try await RehydrateCacheUseCase.liveValue.execute()
        }

        #expect(refreshedIDs == [playlist.id])
    }

    @Test("rehydrate_skipsPlaylistsThatAlreadyHaveChannels")
    func rehydrateSkipsPlaylistsThatAlreadyHaveChannels() async throws {
        let db = try makeTestDatabase()
        let playlist = Playlist.mock()
        var refreshedIDs: [UUID] = []

        try await withDependencies {
            $0.database = db
            $0.userDefaultsClient = makeTestUserDefaultsClient()
            $0.playlistRepository = DefaultPlaylistRepository()
            $0.channelRepository = DefaultChannelRepository()
            $0.favoriteRepository = DefaultFavoriteRepository()
            $0.refreshPlaylistUseCase.execute = { id in refreshedIDs.append(id) }
        } operation: {
            try await DefaultPlaylistRepository().insert(playlist)
            try await DefaultChannelRepository().save([Channel.mock()], playlistID: playlist.id)
            try await RehydrateCacheUseCase.liveValue.execute()
        }

        #expect(refreshedIDs.isEmpty)
    }

    @Test("rehydrate_continuesAfterOnePlaylistFailure")
    func rehydrateContinuesAfterOnePlaylistFailure() async throws {
        let db = try makeTestDatabase()
        let failing = Playlist.mock(name: "Failing")
        let succeeding = Playlist.mock(name: "Succeeding")
        var refreshedIDs: [UUID] = []

        try await withDependencies {
            $0.database = db
            $0.userDefaultsClient = makeTestUserDefaultsClient()
            $0.playlistRepository = DefaultPlaylistRepository()
            $0.channelRepository = DefaultChannelRepository()
            $0.favoriteRepository = DefaultFavoriteRepository()
            $0.refreshPlaylistUseCase.execute = { id in
                refreshedIDs.append(id)
                if id == failing.id { throw URLError(.notConnectedToInternet) }
            }
        } operation: {
            try await DefaultPlaylistRepository().insert(failing)
            try await DefaultPlaylistRepository().insert(succeeding)
            try await RehydrateCacheUseCase.liveValue.execute()
        }

        #expect(Set(refreshedIDs) == Set([failing.id, succeeding.id]))
    }

    @Test("rehydrate_noPlaylistsStored_isNoOp")
    func rehydrateNoPlaylistsStoredIsNoOp() async throws {
        let db = try makeTestDatabase()
        var refreshCalled = false

        try await withDependencies {
            $0.database = db
            $0.userDefaultsClient = makeTestUserDefaultsClient()
            $0.playlistRepository = DefaultPlaylistRepository()
            $0.channelRepository = DefaultChannelRepository()
            $0.favoriteRepository = DefaultFavoriteRepository()
            $0.refreshPlaylistUseCase.execute = { _ in refreshCalled = true }
        } operation: {
            try await RehydrateCacheUseCase.liveValue.execute()
        }

        #expect(refreshCalled == false)
    }
}
