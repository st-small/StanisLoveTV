import Foundation
import SQLiteData

@Table("playlists") nonisolated struct PlaylistRecord: Identifiable {
    let id: UUID
    var name: String
    var urlString: String
    var epgURL: String?
    var lastFetched: Date?
}

extension PlaylistRecord {
    nonisolated var domainModel: Playlist {
        Playlist(
            id: id,
            name: name,
            url: URL(string: urlString)!,
            type: .m3u,
            epgURL: epgURL.flatMap(URL.init(string:)),
            lastUpdated: lastFetched
        )
    }
}
