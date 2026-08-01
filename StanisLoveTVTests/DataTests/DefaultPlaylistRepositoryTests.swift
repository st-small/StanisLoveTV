import Dependencies
import Foundation
import Testing
@testable import StanisLoveTV

private func makeTestUserDefaultsClient() -> UserDefaultsClient {
    nonisolated(unsafe) let defaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
    return UserDefaultsClient(
        data: { defaults.data(forKey: $0) },
        setData: { value, key in defaults.set(value, forKey: key) },
        stringArray: { defaults.stringArray(forKey: $0) },
        setStringArray: { value, key in defaults.set(value, forKey: key) }
    )
}

@Suite("DefaultPlaylistRepository")
struct DefaultPlaylistRepositoryTests {

    @Test("insertsAndFetchesPlaylist")
    func insertsAndFetchesPlaylist() async throws {
        let testDefaults = makeTestUserDefaultsClient()
        let playlist = Playlist.mock(name: "Test Playlist")

        try await withDependencies {
            $0.userDefaultsClient = testDefaults
        } operation: {
            let repo = await DefaultPlaylistRepository()
            try await repo.insert(playlist)
            let all = try await repo.fetchAll()
            #expect(all.count == 1)
            #expect(all[0].name == "Test Playlist")
            #expect(all[0].id == playlist.id)
        }
    }

    @Test("deletePersistsRemoval")
    func deletePersistsRemoval() async throws {
        let testDefaults = makeTestUserDefaultsClient()
        let playlist = Playlist.mock()

        try await withDependencies {
            $0.userDefaultsClient = testDefaults
        } operation: {
            let repo = await DefaultPlaylistRepository()
            try await repo.insert(playlist)
            try await repo.delete(id: playlist.id)
            let all = try await repo.fetchAll()
            #expect(all.isEmpty)
        }
    }

    @Test("updateLastFetched_persists")
    func updateLastFetchedPersists() async throws {
        let testDefaults = makeTestUserDefaultsClient()
        let playlist = Playlist.mock()
        let date = Date(timeIntervalSince1970: 1_700_000_000)

        try await withDependencies {
            $0.userDefaultsClient = testDefaults
        } operation: {
            let repo = await DefaultPlaylistRepository()
            try await repo.insert(playlist)
            try await repo.updateLastFetched(id: playlist.id, date: date)
            let fetched = try await repo.fetch(id: playlist.id)
            #expect(fetched?.lastUpdated == date)
        }
    }

    @Test("updateEPGURL_persists")
    func updateEPGURLPersists() async throws {
        let testDefaults = makeTestUserDefaultsClient()
        let playlist = Playlist.mock()
        let epgURL = URL(string: "https://example.com/epg.xml")!

        try await withDependencies {
            $0.userDefaultsClient = testDefaults
        } operation: {
            let repo = await DefaultPlaylistRepository()
            try await repo.insert(playlist)
            try await repo.updateEPGURL(id: playlist.id, url: epgURL)
            let all = try await repo.fetchAll()
            #expect(all.first?.epgURL == epgURL)
        }
    }

    @Test("survivesReencodeRoundTrip_allFieldsPreserved")
    func survivesReencodeRoundTripAllFieldsPreserved() async throws {
        let testDefaults = makeTestUserDefaultsClient()
        let playlist = Playlist.mock(
            name: "Round Trip",
            url: URL(string: "https://example.com/rt.m3u")!,
            type: .m3uPlus,
            epgURL: URL(string: "https://example.com/rt-epg.xml"),
            lastUpdated: Date(timeIntervalSince1970: 1_700_000_000)
        )

        try await withDependencies {
            $0.userDefaultsClient = testDefaults
        } operation: {
            try await DefaultPlaylistRepository().insert(playlist)
        }

        // Fresh repository instance, same backing store — forces a real decode,
        // not just reading a value still held in memory.
        let refetched = try await withDependencies {
            $0.userDefaultsClient = testDefaults
        } operation: {
            try await DefaultPlaylistRepository().fetch(id: playlist.id)
        }

        #expect(refetched?.name == playlist.name)
        #expect(refetched?.url == playlist.url)
        #expect(refetched?.type == playlist.type)
        #expect(refetched?.epgURL == playlist.epgURL)
        #expect(refetched?.lastUpdated == playlist.lastUpdated)
    }

    @Test("corruptedStoredJSON_returnsEmptyArray_notCrash")
    func corruptedStoredJSONReturnsEmptyArrayNotCrash() async throws {
        let testDefaults = makeTestUserDefaultsClient()
        testDefaults.setData(Data("not valid json".utf8), PersistenceKeys.storedPlaylistsV1)

        try await withDependencies {
            $0.userDefaultsClient = testDefaults
        } operation: {
            let repo = await DefaultPlaylistRepository()
            let all = try await repo.fetchAll()
            #expect(all.isEmpty)
        }
    }
}
