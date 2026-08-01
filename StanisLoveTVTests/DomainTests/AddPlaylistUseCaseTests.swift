import Dependencies
import Foundation
import SQLiteData
import Testing
@testable import StanisLoveTV

private func makeTestDatabase() throws -> DatabaseStack {
    let queue = try DatabaseQueue()
    var migrator = DatabaseMigrator()
    Migrations.register(in: &migrator)
    try migrator.migrate(queue)
    return DatabaseStack(writer: queue)
}

private func makeTestUserDefaultsClient() -> UserDefaultsClient {
    nonisolated(unsafe) let defaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
    return UserDefaultsClient(
        data: { defaults.data(forKey: $0) },
        setData: { value, key in defaults.set(value, forKey: key) },
        stringArray: { defaults.stringArray(forKey: $0) },
        setStringArray: { value, key in defaults.set(value, forKey: key) }
    )
}

private let sampleM3U = """
#EXTM3U url-tvg="http://example.com/epg.xml"
#EXTINF:-1 tvg-id="bbc1" group-title="UK",BBC One
http://example.com/bbc1.m3u8
"""

private let sampleM3UNoEPG = """
#EXTM3U
#EXTINF:-1 group-title="Movies",My Movie Channel
http://example.com/movies.m3u8
"""

private func writeTempM3U(_ content: String, filename: String) throws -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
    try content.write(to: url, atomically: true, encoding: .utf8)
    return url
}

@Suite("AddPlaylistUseCase")
struct AddPlaylistUseCaseTests {

    @Test("Valid URL inserts playlist and saves channels")
    func addPlaylist_validURL_insertsAndFetchesChannels() async throws {
        let db = try makeTestDatabase()
        let testDefaults = makeTestUserDefaultsClient()
        let playlist = Playlist.mock(url: URL(string: "http://example.com/p.m3u")!)

        try await withDependencies {
            $0.database = db
            $0.userDefaultsClient = testDefaults
            $0.playlistRepository = await DefaultPlaylistRepository()
            $0.channelRepository = DefaultChannelRepository()
            $0.networkService.downloadToCache = { _, filename in
                try writeTempM3U(sampleM3U, filename: filename)
            }
        } operation: {
            try await AddPlaylistUseCase.liveValue.execute(playlist)
        }

        let insertedPlaylists = try await withDependencies {
            $0.database = db
            $0.userDefaultsClient = testDefaults
        } operation: {
            try await DefaultPlaylistRepository().fetchAll()
        }
        let insertedChannels = try await withDependencies {
            $0.database = db
            $0.userDefaultsClient = testDefaults
            $0.favoriteRepository = await DefaultFavoriteRepository()
        } operation: {
            try await DefaultChannelRepository().fetchAll(playlistID: playlist.id)
        }

        #expect(insertedPlaylists.count == 1)
        #expect(insertedChannels.count == 1)
        #expect(insertedChannels[0].name == "BBC One")
    }

    @Test("Invalid URL scheme throws streamURLInvalid")
    func addPlaylist_invalidURL_throwsStreamURLInvalid() async throws {
        let playlist = Playlist.mock(url: URL(string: "ftp://example.com/p.m3u")!)
        await #expect(throws: AppError.streamURLInvalid) {
            try await AddPlaylistUseCase.liveValue.execute(playlist)
        }
    }

    @Test("Network failure does not insert playlist")
    func addPlaylist_networkFailure_doesNotInsertPlaylist() async throws {
        let db = try makeTestDatabase()
        let testDefaults = makeTestUserDefaultsClient()
        let playlist = Playlist.mock(url: URL(string: "http://example.com/p.m3u")!)

        await withDependencies {
            $0.database = db
            $0.userDefaultsClient = testDefaults
            $0.playlistRepository = await DefaultPlaylistRepository()
            $0.channelRepository = DefaultChannelRepository()
            $0.networkService.downloadToCache = { _, _ in throw URLError(.notConnectedToInternet) }
        } operation: {
            try? await AddPlaylistUseCase.liveValue.execute(playlist)
        }

        let playlists = try await withDependencies {
            $0.database = db
            $0.userDefaultsClient = testDefaults
        } operation: {
            try await DefaultPlaylistRepository().fetchAll()
        }
        #expect(playlists.isEmpty)
    }

    @Test("Manual EPG URL takes priority over url-tvg in M3U header")
    func addPlaylist_manualEPGURL_takesHighestPriority() async throws {
        let db = try makeTestDatabase()
        let testDefaults = makeTestUserDefaultsClient()
        let manualEPG = URL(string: "http://manual.example.com/epg.xml")!
        let playlist = Playlist.mock(url: URL(string: "http://example.com/p.m3u")!, epgURL: manualEPG)

        try await withDependencies {
            $0.database = db
            $0.userDefaultsClient = testDefaults
            $0.playlistRepository = await DefaultPlaylistRepository()
            $0.channelRepository = DefaultChannelRepository()
            $0.networkService.downloadToCache = { _, filename in
                try writeTempM3U(sampleM3U, filename: filename)
            }
        } operation: {
            try await AddPlaylistUseCase.liveValue.execute(playlist)
        }

        let result = try await withDependencies {
            $0.database = db
            $0.userDefaultsClient = testDefaults
        } operation: {
            try await DefaultPlaylistRepository().fetchAll()
        }
        #expect(result.first?.epgURL == manualEPG)
    }

    @Test("No manual EPG: extracts url-tvg from M3U header")
    func addPlaylist_noManualEPG_extractsFromHeader() async throws {
        let db = try makeTestDatabase()
        let testDefaults = makeTestUserDefaultsClient()
        let playlist = Playlist.mock(url: URL(string: "http://example.com/p.m3u")!, epgURL: nil)

        try await withDependencies {
            $0.database = db
            $0.userDefaultsClient = testDefaults
            $0.playlistRepository = await DefaultPlaylistRepository()
            $0.channelRepository = DefaultChannelRepository()
            $0.networkService.downloadToCache = { _, filename in
                try writeTempM3U(sampleM3U, filename: filename)
            }
        } operation: {
            try await AddPlaylistUseCase.liveValue.execute(playlist)
        }

        let result = try await withDependencies {
            $0.database = db
            $0.userDefaultsClient = testDefaults
        } operation: {
            try await DefaultPlaylistRepository().fetchAll()
        }
        #expect(result.first?.epgURL == URL(string: "http://example.com/epg.xml"))
    }

    @Test("No EPG in M3U header and no manual URL: epgURL is nil")
    func addPlaylist_noEPGAnywhere_leavesEPGURLNil() async throws {
        let db = try makeTestDatabase()
        let testDefaults = makeTestUserDefaultsClient()
        let playlist = Playlist.mock(url: URL(string: "http://example.com/p.m3u")!, epgURL: nil)

        try await withDependencies {
            $0.database = db
            $0.userDefaultsClient = testDefaults
            $0.playlistRepository = await DefaultPlaylistRepository()
            $0.channelRepository = DefaultChannelRepository()
            $0.networkService.downloadToCache = { _, filename in
                try writeTempM3U(sampleM3UNoEPG, filename: filename)
            }
        } operation: {
            try await AddPlaylistUseCase.liveValue.execute(playlist)
        }

        let result = try await withDependencies {
            $0.database = db
            $0.userDefaultsClient = testDefaults
        } operation: {
            try await DefaultPlaylistRepository().fetchAll()
        }
        #expect(result.first?.epgURL == nil)
    }

    @Test("Refresh does not overwrite manually set EPG URL")
    func refreshPlaylist_doesNotOverwriteManualEPGURL() async throws {
        let db = try makeTestDatabase()
        let testDefaults = makeTestUserDefaultsClient()
        let manualEPG = URL(string: "http://manual.example.com/epg.xml")!
        let playlist = Playlist.mock(url: URL(string: "http://example.com/p.m3u")!, epgURL: manualEPG)

        try await withDependencies {
            $0.database = db
            $0.userDefaultsClient = testDefaults
            $0.playlistRepository = await DefaultPlaylistRepository()
            $0.channelRepository = DefaultChannelRepository()
            $0.networkService.downloadToCache = { _, filename in
                try writeTempM3U(sampleM3U, filename: filename)
            }
        } operation: {
            try await AddPlaylistUseCase.liveValue.execute(playlist)
            try await RefreshPlaylistUseCase.liveValue.execute(playlist.id)
        }

        let result = try await withDependencies {
            $0.database = db
            $0.userDefaultsClient = testDefaults
        } operation: {
            try await DefaultPlaylistRepository().fetchAll()
        }
        #expect(result.first?.epgURL == manualEPG)
    }
}
