import Foundation

enum PlaylistType: String, Sendable, Codable {
    case m3u
    case m3uPlus
}

nonisolated struct Playlist: Identifiable, Sendable {
    let id: UUID
    let name: String
    let url: URL
    let type: PlaylistType
    var epgURL: URL?
    var lastUpdated: Date?
}
