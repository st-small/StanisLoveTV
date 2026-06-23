import Foundation

struct Channel: Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    let streamURL: URL
    let logoURL: URL?
    let groupTitle: String
    let tvgID: String?
    var isFavorite: Bool
}
