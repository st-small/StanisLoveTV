import Foundation

protocol ChannelRepository: Sendable {
    func fetchAll(playlistID: UUID) async throws -> [Channel]
    func fetchFavorites() async throws -> [Channel]
    func save(_ channels: [Channel], playlistID: UUID) async throws
    func search(query: String, playlistID: UUID) async throws -> [Channel]
    func deleteAll(playlistID: UUID) async throws
}
