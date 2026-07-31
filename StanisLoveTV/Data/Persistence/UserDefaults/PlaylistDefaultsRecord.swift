import Foundation

struct PlaylistDefaultsRecord: Codable, Identifiable, Sendable {
    let id: UUID
    var name: String
    var urlString: String
    var typeRaw: String
    var epgURLString: String?
    var lastFetched: Date?
}

extension PlaylistDefaultsRecord {
    var domainModel: Playlist? {
        guard let url = URL(string: urlString) else { return nil }
        return Playlist(
            id: id,
            name: name,
            url: url,
            type: PlaylistType(rawValue: typeRaw) ?? .m3u,
            epgURL: epgURLString.flatMap(URL.init(string:)),
            lastUpdated: lastFetched
        )
    }

    static func from(_ playlist: Playlist) -> PlaylistDefaultsRecord {
        PlaylistDefaultsRecord(
            id: playlist.id,
            name: playlist.name,
            urlString: playlist.url.absoluteString,
            typeRaw: playlist.type.rawValue,
            epgURLString: playlist.epgURL?.absoluteString,
            lastFetched: playlist.lastUpdated
        )
    }
}
