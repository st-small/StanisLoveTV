import Dependencies
import Foundation

actor DefaultFavoriteRepository: FavoriteRepository {
    @Dependency(\.userDefaultsClient) private var defaults

    /// `UserDefaults` isn't guaranteed to reflect a `set()` on the very next `get()`
    /// under rapid successive calls (CFPreferences-backed suites in particular).
    /// Caching in actor-isolated state — rather than re-reading `UserDefaults` on
    /// every call — makes correctness depend only on actor isolation, which Swift
    /// does guarantee, instead of on `UserDefaults` read-after-write timing, which
    /// it doesn't.
    private var cachedKeys: Set<String>?

    func fetchAll() async throws -> Set<String> {
        loadKeys()
    }

    func toggle(favoriteKey: String) async throws -> Bool {
        var keys = loadKeys()
        let isNowFavorite: Bool
        if keys.remove(favoriteKey) != nil {
            isNowFavorite = false
        } else {
            keys.insert(favoriteKey)
            isNowFavorite = true
        }
        cachedKeys = keys
        defaults.setStringArray(Array(keys), PersistenceKeys.favoriteChannelKeysV1)
        return isNowFavorite
    }

    private func loadKeys() -> Set<String> {
        if let cachedKeys { return cachedKeys }
        let keys = Set(defaults.stringArray(PersistenceKeys.favoriteChannelKeysV1) ?? [])
        cachedKeys = keys
        return keys
    }
}
