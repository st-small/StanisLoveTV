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

@Suite("DeletePlaylistUseCase")
struct DeletePlaylistUseCaseTests {

    @Test("delete_removesPlaylistFromRepository")
    func deleteRemovesPlaylistFromRepository() async throws {
        let db = try makeTestDatabase()
        let playlist = Playlist.mock()

        try await withDependencies {
            $0.database = db
            $0.userDefaultsClient = makeTestUserDefaultsClient()
            $0.playlistRepository = DefaultPlaylistRepository()
            $0.channelRepository = DefaultChannelRepository()
            $0.favoriteRepository = DefaultFavoriteRepository()
        } operation: {
            try await DefaultPlaylistRepository().insert(playlist)
            try await DeletePlaylistUseCase.liveValue.execute(playlist.id)
            let remaining = try await DefaultPlaylistRepository().fetchAll()
            #expect(remaining.isEmpty)
        }
    }

    @Test("delete_alsoDeletesItsChannels")
    func deleteAlsoDeletesItsChannels() async throws {
        // Critical: playlists moved to UserDefaults in v3, so SQLite's
        // ON DELETE CASCADE no longer applies — this use case is now the only
        // thing preventing orphaned channel rows.
        let db = try makeTestDatabase()
        let playlist = Playlist.mock()

        try await withDependencies {
            $0.database = db
            $0.userDefaultsClient = makeTestUserDefaultsClient()
            $0.playlistRepository = DefaultPlaylistRepository()
            $0.channelRepository = DefaultChannelRepository()
            $0.favoriteRepository = DefaultFavoriteRepository()
        } operation: {
            try await DefaultPlaylistRepository().insert(playlist)
            try await DefaultChannelRepository().save(
                [Channel.mock(id: UUID(), name: "Ch 1"), Channel.mock(id: UUID(), name: "Ch 2")],
                playlistID: playlist.id
            )

            try await DeletePlaylistUseCase.liveValue.execute(playlist.id)

            let remaining = try await DefaultChannelRepository().fetchAll(playlistID: playlist.id)
            #expect(remaining.isEmpty)
        }
    }
}
