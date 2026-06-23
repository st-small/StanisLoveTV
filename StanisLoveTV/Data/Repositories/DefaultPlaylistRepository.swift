import Dependencies
import Foundation
import SQLiteData

final class DefaultPlaylistRepository: PlaylistRepository {
    @Dependency(\.database) private var db

    func fetchAll() async throws -> [Playlist] {
        try await db.writer.read { database in
            try PlaylistRecord.fetchAll(database).map(\.domainModel)
        }
    }

    func insert(_ playlist: Playlist) async throws {
        try await db.writer.write { database in
            try PlaylistRecord.insert {
                PlaylistRecord.Draft(
                    id: playlist.id,
                    name: playlist.name,
                    urlString: playlist.url.absoluteString,
                    epgURL: playlist.epgURL?.absoluteString,
                    lastFetched: playlist.lastUpdated
                )
            }.execute(database)
        }
    }

    func delete(id: UUID) async throws {
        try await db.writer.write { database in
            try PlaylistRecord.find(id).delete().execute(database)
        }
    }

    func updateLastFetched(id: UUID, date: Date) async throws {
        try await db.writer.write { database in
            try PlaylistRecord.find(id).update {
                $0.lastFetched = #bind(date)
            }.execute(database)
        }
    }

    func updateEPGURL(id: UUID, url: URL?) async throws {
        try await db.writer.write { database in
            let epgString = url?.absoluteString
            try PlaylistRecord.find(id).update {
                $0.epgURL = #bind(epgString)
            }.execute(database)
        }
    }
}
