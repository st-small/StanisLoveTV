import Dependencies
import Foundation
import SQLiteData

final class DefaultFavoriteRepository: FavoriteRepository {
    @Dependency(\.database) private var db

    func fetchAll() async throws -> [UUID] {
        try await db.writer.read { database in
            try FavoriteRecord.fetchAll(database).map(\.id)
        }
    }

    func toggle(channelID: UUID) async throws -> Bool {
        try await db.writer.write { database in
            if try FavoriteRecord.find(channelID).fetchOne(database) != nil {
                try FavoriteRecord.find(channelID).delete().execute(database)
                return false
            } else {
                try FavoriteRecord.insert {
                    FavoriteRecord(id: channelID, addedAt: Date())
                }.execute(database)
                return true
            }
        }
    }
}
