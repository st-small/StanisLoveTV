import Foundation

protocol FavoriteRepository: Sendable {
    func fetchAll() async throws -> [UUID]
    func toggle(channelID: UUID) async throws -> Bool
}
