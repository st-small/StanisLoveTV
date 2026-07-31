import Foundation
import SQLiteData
import Testing
@testable import StanisLoveTV

@Suite("Migration v3 — move playlists/favorites to UserDefaults")
struct MigrationV3Tests {

    @Test("migrationV3_dropsPlaylistsAndFavoritesTables")
    func migrationV3DropsPlaylistsAndFavoritesTables() throws {
        let queue = try DatabaseQueue()
        var migrator = DatabaseMigrator()
        Migrations.register(in: &migrator)
        try migrator.migrate(queue)

        let tableNames: Set<String> = try queue.read { db in
            Set(try String.fetchAll(db, sql: "SELECT name FROM sqlite_master WHERE type = 'table'"))
        }

        #expect(!tableNames.contains("playlists"))
        #expect(!tableNames.contains("favorites"))
        #expect(tableNames.contains("channels"))
        #expect(tableNames.contains("epgPrograms"))
    }

    @Test("migrationV3_preservesExistingChannelsAndEPGRows")
    func migrationV3PreservesExistingChannelsAndEPGRows() throws {
        let queue = try DatabaseQueue()
        var migrator = DatabaseMigrator()
        Migrations.register(in: &migrator)

        // Seed data against the pre-v3 schema, where "channels" still FK-references
        // "playlists", so a real parent row is required.
        try migrator.migrate(queue, upTo: "v2_playlist_epg_url")

        let playlistID = UUID().uuidString
        let channelID = UUID().uuidString
        try queue.write { db in
            try db.execute(
                sql: """
                    INSERT INTO "playlists" ("id", "name", "urlString") VALUES (?, ?, ?)
                    """,
                arguments: [playlistID, "Seed Playlist", "https://example.com/p.m3u"]
            )
            try db.execute(
                sql: """
                    INSERT INTO "channels" ("id", "playlistID", "name", "streamURL") VALUES (?, ?, ?, ?)
                    """,
                arguments: [channelID, playlistID, "Seed Channel", "https://example.com/s.m3u8"]
            )
            try db.execute(
                sql: """
                    INSERT INTO "epgPrograms" ("id", "channelID", "title", "startTime", "endTime")
                    VALUES (?, ?, ?, ?, ?)
                    """,
                arguments: [
                    UUID().uuidString, "seed-channel", "Seed Program",
                    "2026-01-01T00:00:00Z", "2026-01-01T01:00:00Z",
                ]
            )
        }

        // Continue the same migrator through v3.
        try migrator.migrate(queue)

        let (channelCount, epgCount) = try queue.read { db in
            let channelCount = try Int.fetchOne(
                db, sql: "SELECT COUNT(*) FROM \"channels\" WHERE id = ?", arguments: [channelID]
            ) ?? 0
            let epgCount = try Int.fetchOne(
                db, sql: "SELECT COUNT(*) FROM \"epgPrograms\" WHERE channelID = 'seed-channel'"
            ) ?? 0
            return (channelCount, epgCount)
        }

        #expect(channelCount == 1)
        #expect(epgCount == 1)
    }

    @Test("migrationV3_channelsInsertSucceedsWithoutParentPlaylistsRow")
    func migrationV3ChannelsInsertSucceedsWithoutParentPlaylistsRow() throws {
        let queue = try DatabaseQueue()
        var migrator = DatabaseMigrator()
        Migrations.register(in: &migrator)
        try migrator.migrate(queue)

        // "playlists" no longer exists at all, so this playlistID is necessarily
        // orphaned — if the FK constraint were still active, this insert would throw.
        try queue.write { db in
            try db.execute(
                sql: """
                    INSERT INTO "channels" ("id", "playlistID", "name", "streamURL") VALUES (?, ?, ?, ?)
                    """,
                arguments: [UUID().uuidString, UUID().uuidString, "Orphan Channel", "https://example.com/o.m3u8"]
            )
        }
    }
}
