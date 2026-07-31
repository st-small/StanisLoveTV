import Foundation

struct Channel: Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    let streamURL: URL
    let logoURL: URL?
    let groupTitle: String
    let tvgID: String?
    var isFavorite: Bool

    /// Stable identity for favorites across M3U re-parses, where `id` is regenerated
    /// on every refresh. Falls back to `streamURL` when the provider omits `tvg-id`.
    var favoriteKey: String { tvgID ?? streamURL.absoluteString }
}
