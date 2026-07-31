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

// Playlist and favorite persistence moved to UserDefaults (see
// DefaultPlaylistRepositoryTests.swift, DefaultFavoriteRepositoryTests.swift,
// DefaultChannelRepositoryTests.swift, DeletePlaylistUseCaseTests.swift). This suite
// now covers only what's actually left in SQLite: channels and EPG programs.
@Suite("SQLite Repository Integration (Channels & EPG)")
struct RepositoryIntegrationTests {

    @Test("EPG prunes stale rows on replace")
    func epgPrunesStaleRowsOnReplace() async throws {
        let db = try makeTestDatabase()
        let repo: any EPGRepository = withDependencies { $0.database = db } operation: {
            DefaultEPGRepository()
        }

        let staleProgram = EPGProgram.mock(
            channelID: "other-channel",
            startTime: Date(timeIntervalSinceNow: -200_000),
            endTime: Date(timeIntervalSinceNow: -196_400)
        )
        try await repo.replaceAll(channelID: "other-channel", programs: [staleProgram])

        let freshProgram = EPGProgram.mock(channelID: "ch1")
        try await repo.replaceAll(channelID: "ch1", programs: [freshProgram])

        let remaining = try await repo.fetchPrograms(channelID: "other-channel", after: .distantPast)
        #expect(remaining.isEmpty)
    }

    @Test("search returns matching channels")
    func searchReturnsMatchingChannels() async throws {
        let db = try makeTestDatabase()
        let playlistID = UUID()

        let sports = Channel.mock(id: UUID(), name: "Sport News", groupTitle: "Sports")
        let movies = Channel.mock(id: UUID(), name: "Cinema HD", groupTitle: "Movies")

        // No FK to a "playlists" row is needed since migration v3 — channels only
        // need a playlistID value, not an existing parent.
        try await withDependencies {
            $0.database = db
            $0.userDefaultsClient = makeTestUserDefaultsClient()
            $0.favoriteRepository = DefaultFavoriteRepository()
        } operation: {
            try await DefaultChannelRepository().save([sports, movies], playlistID: playlistID)
        }

        let results = try await withDependencies {
            $0.database = db
            $0.userDefaultsClient = makeTestUserDefaultsClient()
            $0.favoriteRepository = DefaultFavoriteRepository()
        } operation: {
            try await DefaultChannelRepository().search(query: "sport", playlistID: playlistID)
        }
        #expect(results.count == 1)
        #expect(results[0].name == "Sport News")
    }
}
