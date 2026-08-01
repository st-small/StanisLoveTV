import Dependencies
import Foundation
import SQLiteData

final class DefaultChannelRepository: ChannelRepository {
    @Dependency(\.database) private var db
    @Dependency(\.favoriteRepository) private var favoriteRepository

    nonisolated init() {}

    func fetchAll(playlistID: UUID) async throws -> [Channel] {
        let channels = try await db.writer.read { database in
            try ChannelRecord
                .where { $0.playlistID.eq(playlistID) }
                .order(by: \.position)
                .fetchAll(database)
                .map(\.domainModel)
        }
        return try await resolveFavorites(channels)
    }

    func fetchFavorites() async throws -> [Channel] {
        let favoriteKeys = try await favoriteRepository.fetchAll()
        guard !favoriteKeys.isEmpty else { return [] }
        return try await db.writer.read { database in
            try ChannelRecord
                .fetchAll(database)
                .map(\.domainModel)
                .filter { favoriteKeys.contains($0.favoriteKey) }
                .map { channel in
                    var channel = channel
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

    func search(query: String, playlistID: UUID) async throws -> [Channel] {
        let channels = try await db.writer.read { database in
            let pattern = "%\(query)%"
            return try #sql(
                """
                SELECT \(ChannelRecord.columns)
                FROM \(ChannelRecord.self)
                WHERE \(ChannelRecord.playlistID) = \(playlistID)
                  AND (\(ChannelRecord.name) LIKE \(bind: pattern)
                       OR \(ChannelRecord.groupTitle) LIKE \(bind: pattern))
                """,
                as: ChannelRecord.self
            )
            .fetchAll(database)
            .map(\.domainModel)
        }
        return try await resolveFavorites(channels)
    }

    func deleteAll(playlistID: UUID) async throws {
        try await db.writer.write { database in
            try ChannelRecord
                .where { $0.playlistID.eq(playlistID) }
                .delete()
                .execute(database)
        }
    }

    /// Favorites live in `UserDefaults` (see `DefaultFavoriteRepository`), not SQLite,
    /// so membership is resolved in memory rather than via SQL join.
    private func resolveFavorites(_ channels: [Channel]) async throws -> [Channel] {
        guard !channels.isEmpty else { return channels }
        let favoriteKeys = try await favoriteRepository.fetchAll()
        guard !favoriteKeys.isEmpty else { return channels }
        return channels.map { channel in
            var channel = channel
            channel.isFavorite = favoriteKeys.contains(channel.favoriteKey)
            return channel
        }
    }
}
