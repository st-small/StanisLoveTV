import Foundation

extension Playlist {
    static func mock(
        id: UUID = UUID(),
        name: String = "Mock Playlist",
        url: URL = URL(string: "https://example.com/playlist.m3u")!,
        type: PlaylistType = .m3u,
        epgURL: URL? = nil,
        lastUpdated: Date? = nil
    ) -> Playlist {
        Playlist(
            id: id,
            name: name,
            url: url,
            type: type,
            epgURL: epgURL,
            lastUpdated: lastUpdated
        )
    }
}
