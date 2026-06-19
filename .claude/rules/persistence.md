---
paths:
  - "StanisLoveTV/Data/Persistence/**"
  - "StanisLoveTV/Data/Repositories/**"
---

# Persistence Rules — SQLiteData

**Stack**: SQLiteData (PointFree) — GRDB + StructuredQueries.
**UserDefaults**: scalar flags only (last channel id, EPG TTL timestamp, volume).
**File cache**: M3U/EPG XML → `Caches` directory, excluded from iCloud backup.

## Tables

| Table | Purpose |
|-------|---------|
| `playlists` | Playlist URLs + metadata |
| `channels` | Parsed channels per playlist |
| `favorites` | Favorited channel IDs |
| `epgPrograms` | EPG cache (pruned at 48h) |

## @Table Structs

`nonisolated struct` is required — `@Table` does not support `class` or `actor`-isolated types.

```swift
@Table nonisolated struct PlaylistRecord: Identifiable {
    let id: UUID
    var name: String
    var urlString: String
    var lastFetched: Date?
}

@Table nonisolated struct ChannelRecord: Identifiable {
    let id: UUID
    var playlistID: UUID
    var name: String
    var streamURL: String
    var logoURL: String?
    var groupTitle: String
    var tvgID: String?
    var position: Int
}

@Table nonisolated struct FavoriteRecord: Identifiable {
    let id: UUID        // == channelID
    var addedAt: Date
}

@Table nonisolated struct EPGProgramRecord: Identifiable {
    let id: UUID
    var channelID: String   // matches Channel.tvgID
    var title: String
    var startTime: Date
    var endTime: Date
    var programDescription: String?
    var fetchedAt: Date     // for TTL pruning
}
```

## DatabaseStack

```swift
struct DatabaseStack {
    let writer: any DatabaseWriter

    static func live() throws -> DatabaseStack {
        let url = try FileManager.default
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("stanislove.sqlite")
        var config = Configuration()
        config.foreignKeysEnabled = true
        let queue = try DatabaseQueue(path: url.path, configuration: config)
        var migrator = DatabaseMigrator()
        Migrations.register(in: &migrator)
        try migrator.migrate(queue)
        return DatabaseStack(writer: queue)
    }
}

extension DatabaseStack: DependencyKey {
    static let liveValue: DatabaseStack = {
        do { return try DatabaseStack.live() }
        catch { fatalError("Failed to open database: \(error)") }
    }()
    static let testValue = DatabaseStack(writer: try! DatabaseQueue()) // in-memory
}

extension DependencyValues {
    var database: DatabaseStack {
        get { self[DatabaseStack.self] }
        set { self[DatabaseStack.self] = newValue }
    }
}
```

## Migrations — always use `#sql` macro + `DatabaseMigrator`

```swift
enum Migrations {
    static func register(in migrator: inout DatabaseMigrator) {
        migrator.registerMigration("v1_initial") { db in
            try #sql("""
                CREATE TABLE "playlists" (
                    "id" TEXT PRIMARY KEY NOT NULL DEFAULT (uuid()),
                    "name" TEXT NOT NULL DEFAULT '',
                    "urlString" TEXT NOT NULL,
                    "lastFetched" TEXT
                ) STRICT
                """).execute(db)

            try #sql("""
                CREATE TABLE "channels" (
                    "id" TEXT PRIMARY KEY NOT NULL DEFAULT (uuid()),
                    "playlistID" TEXT NOT NULL REFERENCES "playlists"("id") ON DELETE CASCADE,
                    "name" TEXT NOT NULL DEFAULT '',
                    "streamURL" TEXT NOT NULL,
                    "logoURL" TEXT,
                    "groupTitle" TEXT NOT NULL DEFAULT '',
                    "tvgID" TEXT,
                    "position" INTEGER NOT NULL DEFAULT 0
                ) STRICT
                """).execute(db)

            try #sql("""
                CREATE TABLE "favorites" (
                    "id" TEXT PRIMARY KEY NOT NULL,
                    "addedAt" TEXT NOT NULL DEFAULT (datetime('now'))
                ) STRICT
                """).execute(db)

            try #sql("""
                CREATE TABLE "epgPrograms" (
                    "id" TEXT PRIMARY KEY NOT NULL DEFAULT (uuid()),
                    "channelID" TEXT NOT NULL,
                    "title" TEXT NOT NULL DEFAULT '',
                    "startTime" TEXT NOT NULL,
                    "endTime" TEXT NOT NULL,
                    "programDescription" TEXT,
                    "fetchedAt" TEXT NOT NULL DEFAULT (datetime('now'))
                ) STRICT
                """).execute(db)

            try #sql("""
                CREATE INDEX "idx_channels_playlistID" ON "channels" ("playlistID")
                """).execute(db)

            try #sql("""
                CREATE INDEX "idx_epgPrograms_channelID_start" ON "epgPrograms" ("channelID", "startTime")
                """).execute(db)
        }
        // Each future schema change = new registerMigration("v2_...") block
        // Migrations are irreversible — never DROP columns or tables without a new version
    }
}
```

## Repository Pattern

- `db.writer.read { }` for reads, `db.writer.write { }` for writes
- Insert uses `RecordType.Draft(...)`, not `RecordType(...)` directly

```swift
final class DefaultChannelRepository: ChannelRepository {
    @Dependency(\.database) private var db

    func fetchAll(playlistID: UUID) async throws -> [Channel] {
        try await db.writer.read { database in
            try ChannelRecord
                .where { .playlistID.eq(playlistID) }
                .order(by: \.position)
                .fetchAll(database)
                .map(\.domainModel)
        }
    }

    func save(_ channels: [Channel], playlistID: UUID) async throws {
        try await db.writer.write { database in
            try ChannelRecord.where { .playlistID.eq(playlistID) }.delete().execute(database)
            for (index, channel) in channels.enumerated() {
                try ChannelRecord.insert {
                    ChannelRecord.Draft(
                        id: channel.id,
                        playlistID: playlistID,
                        name: channel.name,
                        streamURL: channel.streamURL.absoluteString,
                        logoURL: channel.logoURL?.absoluteString,
                        groupTitle: channel.groupTitle,
                        tvgID: channel.tvgID,
                        position: index
                    )
                }.execute(database)
            }
        }
    }
}
```

## Domain Mapping Convention

Every `@Table` struct has a `domainModel` extension in the same file. This is the only place where `@Table` → Domain entity conversion happens.

```swift
extension ChannelRecord {
    var domainModel: Channel {
        Channel(
            id: id,
            name: name,
            streamURL: URL(string: streamURL)!, // safe: validated at M3U parse time
            logoURL: logoURL.flatMap(URL.init),
            groupTitle: groupTitle,
            tvgID: tvgID,
            isFavorite: false // resolved separately via favorites table join
        )
    }
}
```

Reverse mapping (Domain → Draft) lives as a static factory or free function in the same file.
