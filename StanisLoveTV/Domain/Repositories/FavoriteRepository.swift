import Foundation

protocol FavoriteRepository: Sendable {
    func fetchAll() async throws -> Set<String>
    func toggle(favoriteKey: String) async throws -> Bool
}
