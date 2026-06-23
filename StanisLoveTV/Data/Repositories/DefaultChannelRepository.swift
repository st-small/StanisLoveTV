import Dependencies
import Foundation
import SQLiteData

@Selection private struct ChannelFavoriteRow {
    let channel: ChannelRecord
    let favorite: FavoriteRecord?
}

final class DefaultChannelRepository: ChannelRepository {
    @Dependency(\.database) private var db

    func fetchAll(playlistID: UUID) async throws -> [Channel] {
        try await db.writer.read { database in
            let rows = try ChannelRecord
                .where { $0.playlistID.eq(playlistID) }
                .order(by: \.position)
                .leftJoin(FavoriteRecord.all) { $0.id.eq($1.id) }
                .select { ChannelFavoriteRow.Columns(channel: $0, favorite: $1) }
                .fetchAll(database)

            return rows.map { row in
                var channel = row.channel.domainModel
                channel.isFavorite = row.favorite != nil
                return channel
            }
        }
    }

    func fetchFavorites() async throws -> [Channel] {
        try await db.writer.read { database in
            let favoriteIDs = try FavoriteRecord.fetchAll(database).map(\.id)
            guard !favoriteIDs.isEmpty else { return [] }
            return try ChannelRecord
                .where { $0.id.in(favoriteIDs) }
                .fetchAll(database)
                .map { record in
                    var channel = record.domainModel
                    channel.isFavorite = true
                    return channel
                }
        }
    }

    func save(_ channels: [Channel], playlistID: UUID) async throws {
        try await db.writer.write { database in
            try ChannelRecord
                .where { $0.playlistID.eq(playlistID) }
                .delete()
                .execute(database)

            guard !channels.isEmpty else { return }
            let drafts = channels.enumerated().map { index, channel in
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
            }
            try ChannelRecord.insert { drafts }.execute(database)
        }
    }

    func search(query: String) async throws -> [Channel] {
        try await db.writer.read { database in
            let pattern = "%\(query)%"
            return try #sql(
                """
                SELECT \(ChannelRecord.columns)
                FROM \(ChannelRecord.self)
                WHERE \(ChannelRecord.name) LIKE \(pattern)
                   OR \(ChannelRecord.groupTitle) LIKE \(pattern)
                """,
                as: ChannelRecord.self
            )
            .fetchAll(database)
            .map(\.domainModel)
        }
    }
}
