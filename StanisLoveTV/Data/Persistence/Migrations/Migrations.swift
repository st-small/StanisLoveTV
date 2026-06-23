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
    }
}
