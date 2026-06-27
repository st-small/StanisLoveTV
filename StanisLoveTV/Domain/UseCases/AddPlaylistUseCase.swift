import Dependencies
import Foundation

struct AddPlaylistUseCase {
    var execute: (Playlist) async throws -> Void
}

extension AddPlaylistUseCase: DependencyKey {
    static var liveValue: Self {
        .init { playlist in
            guard ["http", "https"].contains(playlist.url.scheme) else {
                throw AppError.streamURLInvalid
            }

            @Dependency(\.networkService) var network
            @Dependency(\.playlistRepository) var playlistRepo
            @Dependency(\.channelRepository) var channelRepo

            // Download and parse before inserting — network failure leaves DB clean
            let cacheFilename = "playlist-\(playlist.id).m3u"
            let localURL = try await network.downloadToCache(playlist.url, cacheFilename)
            let content = try String(contentsOf: localURL, encoding: .utf8)
            let parseResult = try M3UParser().parse(content)

            // Manual EPG URL from user wins; fall back to url-tvg extracted from header
            let resolvedEPGURL = playlist.epgURL ?? parseResult.epgURL

            let finalPlaylist = Playlist(
                id: playlist.id,
                name: playlist.name,
                url: playlist.url,
                type: playlist.type,
                epgURL: resolvedEPGURL,
                lastUpdated: Date()
            )
            try await playlistRepo.insert(finalPlaylist)
            try await channelRepo.save(parseResult.channels, playlistID: playlist.id)
        }
    }

    static let testValue = AddPlaylistUseCase(
        execute: { _ in unimplemented("AddPlaylistUseCase.execute") }
    )
}
