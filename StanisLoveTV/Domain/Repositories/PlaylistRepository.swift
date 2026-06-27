import Foundation

protocol PlaylistRepository: Sendable {
    func fetchAll() async throws -> [Playlist]
    func fetch(id: UUID) async throws -> Playlist?
    func insert(_ playlist: Playlist) async throws
    func delete(id: UUID) async throws
    func updateLastFetched(id: UUID, date: Date) async throws
    func updateEPGURL(id: UUID, url: URL?) async throws
}
