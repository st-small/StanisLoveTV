import Foundation
import SQLiteData

@Table nonisolated struct ChannelRecord: Identifiable {
    let id: UUID
    var playlistID: UUID
    var name: String
    var streamURL: String
    var logoURL: String?
    var groupTitle: String
    var tvgID: String?
    var position: Int
}

extension ChannelRecord {
    nonisolated var domainModel: Channel {
        Channel(
            id: id,
            name: name,
            streamURL: URL(string: streamURL)!,
            logoURL: logoURL.flatMap(URL.init(string:)),
            groupTitle: groupTitle,
            tvgID: tvgID,
            isFavorite: false
        )
    }
}
