import Dependencies
import Foundation

actor DefaultPlaylistRepository: PlaylistRepository {
    @Dependency(\.userDefaultsClient) private var defaults

    /// `UserDefaults` isn't guaranteed to reflect a `set()` on the very next `get()`
    /// under rapid successive calls (CFPreferences-backed suites in particular).
    /// Caching in actor-isolated state — rather than re-reading `UserDefaults` on
    /// every call — makes correctness depend only on actor isolation, which Swift
    /// does guarantee, instead of on `UserDefaults` read-after-write timing, which
    /// it doesn't. See `DefaultFavoriteRepository` for the same pattern.
    private var cachedRecords: [PlaylistDefaultsRecord]?

    func fetchAll() async throws -> [Playlist] {
        loadRecords().compactMap(\.domainModel)
    }

    func fetch(id: UUID) async throws -> Playlist? {
        loadRecords().first { $0.id == id }?.domainModel
    }

    func insert(_ playlist: Playlist) async throws {
        var records = loadRecords()
        records.append(.from(playlist))
        saveRecords(records)
    }

    func delete(id: UUID) async throws {
        var records = loadRecords()
        records.removeAll { $0.id == id }
        saveRecords(records)
    }

    func updateLastFetched(id: UUID, date: Date) async throws {
        var records = loadRecords()
        guard let index = records.firstIndex(where: { $0.id == id }) else { return }
        records[index].lastFetched = date
        saveRecords(records)
    }

    func updateEPGURL(id: UUID, url: URL?) async throws {
        var records = loadRecords()
        guard let index = records.firstIndex(where: { $0.id == id }) else { return }
        records[index].epgURLString = url?.absoluteString
        saveRecords(records)
    }

    /// Corrupted or missing JSON is treated as an empty playlist list rather than
    /// thrown — `UserDefaults` is not a database and callers shouldn't need to
    /// handle decode failures for what is effectively cold-start state.
    private func loadRecords() -> [PlaylistDefaultsRecord] {
        if let cachedRecords { return cachedRecords }
        guard let data = defaults.data(PersistenceKeys.storedPlaylistsV1) else {
            cachedRecords = []
            return []
        }
        let records = (try? JSONDecoder().decode([PlaylistDefaultsRecord].self, from: data)) ?? []
        cachedRecords = records
        return records
    }

    private func saveRecords(_ records: [PlaylistDefaultsRecord]) {
        cachedRecords = records
        let data = try? JSONEncoder().encode(records)
        defaults.setData(data, PersistenceKeys.storedPlaylistsV1)
    }
}
