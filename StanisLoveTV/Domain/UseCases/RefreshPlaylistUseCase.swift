import Dependencies
import Foundation

struct RefreshPlaylistUseCase {
    var execute: (UUID) async throws -> Void
}

extension RefreshPlaylistUseCase: DependencyKey {
    static var liveValue: Self {
        .init { playlistID in
            @Dependency(\.networkService) var network
            @Dependency(\.playlistRepository) var playlistRepo
            @Dependency(\.channelRepository) var channelRepo

            guard let playlist = try await playlistRepo.fetch(id: playlistID) else { return }

            let cacheFilename = "playlist-\(playlistID).m3u"
            let localURL = try await network.downloadToCache(playlist.url, cacheFilename)
            let content = try String(contentsOf: localURL, encoding: .utf8)
            let parseResult = try M3UParser().parse(content)

            // EPG URL is intentionally not updated on refresh — user setting wins
            try await channelRepo.save(parseResult.channels, playlistID: playlistID)
            try await playlistRepo.updateLastFetched(id: playlistID, date: Date())
        }
    }

    static let testValue = RefreshPlaylistUseCase(
        execute: { _ in unimplemented("RefreshPlaylistUseCase.execute") }
    )
}
