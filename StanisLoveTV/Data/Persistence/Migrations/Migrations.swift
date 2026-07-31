import SQLiteData

enum Migrations {
    static func register(in migrator: inout DatabaseMigrator) {
        migrator.registerMigration("v1_initial") { db in
            try #sql("""
                CREATE TABLE "playlists" (
                    "id"          TEXT PRIMARY KEY NOT NULL DEFAULT (uuid()),
                    "name"        TEXT NOT NULL DEFAULT '',
                    "urlString"   TEXT NOT NULL,
                    "lastFetched" TEXT
                ) STRICT
                """).execute(db)

            try #sql("""
                CREATE TABLE "channels" (
                    "id"         TEXT PRIMARY KEY NOT NULL DEFAULT (uuid()),
                    "playlistID" TEXT NOT NULL REFERENCES "playlists"("id") ON DELETE CASCADE,
                    "name"       TEXT NOT NULL DEFAULT '',
                    "streamURL"  TEXT NOT NULL,
                    "logoURL"    TEXT,
                    "groupTitle" TEXT NOT NULL DEFAULT '',
                    "tvgID"      TEXT,
                    "position"   INTEGER NOT NULL DEFAULT 0
                ) STRICT
                """).execute(db)

            try #sql("""
                CREATE TABLE "favorites" (
                    "id"      TEXT PRIMARY KEY NOT NULL,
                    "addedAt" TEXT NOT NULL DEFAULT (datetime('now'))
                ) STRICT
                """).execute(db)

            try #sql("""
                CREATE TABLE "epgPrograms" (
                    "id"                 TEXT PRIMARY KEY NOT NULL DEFAULT (uuid()),
                    "channelID"          TEXT NOT NULL,
                    "title"              TEXT NOT NULL DEFAULT '',
                    "startTime"          TEXT NOT NULL,
                    "endTime"            TEXT NOT NULL,
                    "programDescription" TEXT,
                    "fetchedAt"          TEXT NOT NULL DEFAULT (datetime('now'))
                ) STRICT
                """).execute(db)

            try #sql("""
                CREATE INDEX "idx_channels_playlistID"
                ON "channels" ("playlistID")
                """).execute(db)

            try #sql("""
                CREATE INDEX "idx_epgPrograms_channelID_start"
                ON "epgPrograms" ("channelID", "startTime")
                """).execute(db)
        }

        migrator.registerMigration("v2_playlist_epg_url") { db in
            try #sql("""
                ALTER TABLE "playlists" ADD COLUMN "epgURL" TEXT
                """).execute(db)
        }

        // Playlists and favorites moved to UserDefaults (see DefaultPlaylistRepository /
        // DefaultFavoriteRepository) — they hold non-regenerable user input, but the
        // sqlite file lives in Caches, which tvOS may purge at any time. `channels` and
        // `epgPrograms` stay here: they're derived data, safe to lose and re-fetch.
        migrator.registerMigration("v3_move_playlists_favorites_to_userdefaults") { db in
            // SQLite has no ALTER TABLE ... DROP CONSTRAINT, so the FK to "playlists" is
            // removed by recreating "channels" without it. This must happen before
            // DROP TABLE "playlists" below, or the still-referencing FK blocks the drop.
            try #sql("""
                CREATE TABLE "channels_new" (
                    "id"         TEXT PRIMARY KEY NOT NULL DEFAULT (uuid()),
                    "playlistID" TEXT NOT NULL,
                    "name"       TEXT NOT NULL DEFAULT '',
                    "streamURL"  TEXT NOT NULL,
                    "logoURL"    TEXT,
                    "groupTitle" TEXT NOT NULL DEFAULT '',
                    "tvgID"      TEXT,
                    "position"   INTEGER NOT NULL DEFAULT 0
                ) STRICT
                """).execute(db)

            try #sql("""
                INSERT INTO "channels_new" SELECT * FROM "channels"
                """).execute(db)

            try #sql("""
                DROP TABLE "channels"
                """).execute(db)

            try #sql("""
                ALTER TABLE "channels_new" RENAME TO "channels"
                """).execute(db)

            try #sql("""
                CREATE INDEX "idx_channels_playlistID" ON "channels" ("playlistID")
                """).execute(db)

            try #sql("""
                CREATE INDEX "idx_channels_tvgID" ON "channels" ("tvgID")
                """).execute(db)

            try #sql("""
                DROP TABLE "favorites"
                """).execute(db)

            try #sql("""
                DROP TABLE "playlists"
                """).execute(db)
        }
    }
}
