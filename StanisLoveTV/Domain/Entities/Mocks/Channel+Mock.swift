import Foundation

extension Channel {
    static func mock(
        id: UUID = UUID(),
        name: String = "Mock Channel",
        streamURL: URL = URL(string: "https://example.com/stream.m3u8")!,
        logoURL: URL? = URL(string: "https://example.com/logo.png"),
        groupTitle: String = "Mock Group",
        tvgID: String? = "mock-channel-id",
        isFavorite: Bool = false
    ) -> Channel {
        Channel(
            id: id,
            name: name,
            streamURL: streamURL,
            logoURL: logoURL,
            groupTitle: groupTitle,
            tvgID: tvgID,
            isFavorite: isFavorite
        )
    }
}
