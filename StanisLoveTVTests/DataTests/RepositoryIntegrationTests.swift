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

@Suite("Repository Integration")
struct RepositoryIntegrationTests {

    @Test("inserts and fetches playlist")
    func insertsAndFetchesPlaylist() async throws {
        let db = try makeTestDatabase()
        let repo: any PlaylistRepository = try await withDependencies {
            $0.database = db
        } operation: {
            DefaultPlaylistRepository()
        }

        let playlist = Playlist.mock(name: "Test Playlist")
        try await repo.insert(playlist)

        let all = try await repo.fetchAll()
        #expect(all.count == 1)
        #expect(all[0].name == "Test Playlist")
        #expect(all[0].id == playlist.id)
    }

    @Test("deleting playlist cascades to channels")
    func deletingPlaylistCascadesToChannels() async throws {
        let db = try makeTestDatabase()

        let playlistRepo: any PlaylistRepository = withDependencies {
            $0.database = db
        } operation: { DefaultPlaylistRepository() }

        let channelRepo: any ChannelRepository = withDependencies {
            $0.database = db
        } operation: { DefaultChannelRepository() }

        let playlist = Playlist.mock()
        try await playlistRepo.insert(playlist)

        let channels = [Channel.mock(id: UUID(), name: "Ch 1"), Channel.mock(id: UUID(), name: "Ch 2")]
        try await channelRepo.save(channels, playlistID: playlist.id)

        try await playlistRepo.delete(id: playlist.id)

        let remaining = try await channelRepo.fetchAll(playlistID: playlist.id)
        #expect(remaining.isEmpty)
    }

    @Test("channel favorite flag resolves correctly")
    func channelFavoriteFlagResolvesCorrectly() async throws {
        let db = try makeTestDatabase()

        let playlist = Playlist.mock()
        let channel = Channel.mock()

        try await withDependencies { $0.database = db } operation: {
            try await DefaultPlaylistRepository().insert(playlist)
            try await DefaultChannelRepository().save([channel], playlistID: playlist.id)
        }

        let isFavoriteNow = try await withDependencies { $0.database = db } operation: {
            try await DefaultFavoriteRepository().toggle(channelID: channel.id)
        }
        #expect(isFavoriteNow == true)

        let withFavorite = try await withDependencies { $0.database = db } operation: {
            try await DefaultChannelRepository().fetchAll(playlistID: playlist.id)
        }
        #expect(withFavorite.first?.isFavorite == true)
    }

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
        let playlist = Playlist.mock()

        let sports = Channel.mock(id: UUID(), name: "Sport News", groupTitle: "Sports")
        let movies = Channel.mock(id: UUID(), name: "Cinema HD", groupTitle: "Movies")

        try await withDependencies { $0.database = db } operation: {
            try await DefaultPlaylistRepository().insert(playlist)
            try await DefaultChannelRepository().save([sports, movies], playlistID: playlist.id)
        }

        let results = try await withDependencies { $0.database = db } operation: {
            try await DefaultChannelRepository().search(query: "sport", playlistID: playlist.id)
        }
        #expect(results.count == 1)
        #expect(results[0].name == "Sport News")
    }

    @Test("updateEPGURL persists")
    func updateEPGURLPersists() async throws {
        let db = try makeTestDatabase()
        let playlist = Playlist.mock()
        let epgURL = URL(string: "https://example.com/epg.xml")!

        try await withDependencies { $0.database = db } operation: {
            try await DefaultPlaylistRepository().insert(playlist)
            try await DefaultPlaylistRepository().updateEPGURL(id: playlist.id, url: epgURL)
        }

        let all = try await withDependencies { $0.database = db } operation: {
            try await DefaultPlaylistRepository().fetchAll()
        }
        #expect(all.first?.epgURL == epgURL)
    }
}
