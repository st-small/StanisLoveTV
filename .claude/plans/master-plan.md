# StanisLoveTV — Master Implementation Plan

**Date**: 2026-06-19  
**Last updated**: 2026-07-29 (Phase 6.5 implemented and verified end-to-end; see "Статус: выполнено" in Phase 6.5 for bugs found along the way)  
**Target**: tvOS 27+ | SwiftUI | Clean Architecture | SQLiteData | swift-dependencies  
**Starting state**: Single `ContentView.swift` with placeholder text; `@main` struct in same file (must be extracted)

---

## Phase Overview

| # | Phase | Complexity | Depends on |
|---|-------|-----------|-----------|
| 1 | Foundation & Bootstrap | M | — |
| 2 | Domain Layer | S | Phase 1 |
| 3 | Database & Persistence Layer | M | Phase 2 |
| 4 | Networking & Parsers | M | Phase 2 |
| 5 | M3U Playlist Management | L | Phases 3, 4 |
| 6 | Channel Browser | L | Phase 5 |
| 6.5 | End-to-End Onboarding → Playback Flow | S | Phase 6 |
| 7 | Video Player | XL | Phase 6.5 |
| 8 | EPG Guide | XL | Phases 4, 5 |
| 9 | Favorites | S | Phase 6 |
| 10 | Settings Screen | S | Phases 5, 9 |
| 11 | Polish & Hardening | L | All phases |

---

## Phase 1 — Foundation & Bootstrap

**Goal**: Compilable project skeleton with correct folder structure, SPM packages resolved, DI container ready, design constants defined, app shell showing a four-tab `TabView`.

**Complexity**: M  
**Depends on**: nothing

### Files to create / modify

| Path | Action |
|------|--------|
| `StanisLoveTV/App/StanisLoveTVApp.swift` | Create — extract `@main` here; instantiate `AppState` |
| `StanisLoveTV/App/AppState.swift` | Create — `@Observable AppState`; see sketch below |
| `StanisLoveTV/App/RootView.swift` | Create — `TabView` shell; receives `AppState` via `.environment(appState)` |
| `StanisLoveTV/Core/Constants/Spacing.swift` | Create — `Spacing` + `TVSize` enums |
| `StanisLoveTV/Core/Constants/Typography.swift` | Create — font size constants |
| `StanisLoveTV/Core/Constants/AppConstants.swift` | Create — `AppConstants` with `playlistRefreshInterval`; see note below |
| `StanisLoveTV/Core/Dependencies/DependencyValues+.swift` | Create — central DI registration file |
| `StanisLoveTV/ContentView.swift` | Delete or gut — placeholder only until replaced |

### AppState sketch

`AppState` is the single source of truth for which playlist is currently active. It is created once at app launch and injected into the view hierarchy via SwiftUI's environment. ViewModels that need it receive it via `@Environment` or constructor injection — **never** via `Notification.Name`.

```swift
// App/AppState.swift
import Observation
import Foundation

@Observable
final class AppState {
    var activePlaylistID: UUID? {
        didSet {
            UserDefaults.standard.set(
                activePlaylistID?.uuidString,
                forKey: "activePlaylistID"
            )
        }
    }

    init() {
        if let raw = UserDefaults.standard.string(forKey: "activePlaylistID") {
            activePlaylistID = UUID(uuidString: raw)
        }
    }
}
```

Injection at root:

```swift
// App/StanisLoveTVApp.swift
@main
struct StanisLoveTVApp: App {
    private let appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
        }
    }
}
```

ViewModel consumption patterns:

```swift
// In a View:
@Environment(AppState.self) private var appState

// Passed to a ViewModel via init (preferred for testability):
let viewModel = ChannelListViewModel(appState: appState)

// ChannelListViewModel:
@MainActor @Observable final class ChannelListViewModel {
    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    func load() async {
        let playlistID = appState.activePlaylistID
        // ...
    }
}
```

`SettingsViewModel` writes directly:

```swift
func setActivePlaylist(id: UUID) {
    appState.activePlaylistID = id   // triggers didSet → UserDefaults + @Observable invalidation
}
```

`ChannelListViewModel` and `EPGViewModel` observe `appState.activePlaylistID` automatically via `@Observable` — no `Notification.Name` wiring needed. When `activePlaylistID` changes, any view body that reads it (or any `withObservationTracking` block) reacts immediately.

**No `Notification.Name("activePlaylistDidChange")` anywhere in the codebase.** The `@Observable` mechanism replaces it entirely.

### AppConstants — foreground refresh throttle

```swift
// Core/Constants/AppConstants.swift
enum AppConstants {
    /// Minimum interval between automatic foreground playlist refreshes.
    /// Set to 15 minutes to avoid hammering the server on every focus switch.
    static let playlistRefreshInterval: TimeInterval = 15 * 60  // 900 s
}
```

Usage in `refreshActivePlaylistIfNeeded()`:

```swift
guard let lastFetched = playlist.lastUpdated,
      Date().timeIntervalSince(lastFetched) > AppConstants.playlistRefreshInterval else {
    return  // too recent — skip
}
```

### SPM packages to add in Xcode

```
https://github.com/pointfreeco/swift-dependencies   from: "1.3.0"
https://github.com/pointfreeco/sqlite-data           from: "1.4.0"
https://github.com/onevcat/Kingfisher                from: "8.0.0"
```

Target link: `StanisLoveTV` target links `Dependencies`, `SQLiteData`, `Kingfisher`.  
`SQLiteData` brings GRDB + StructuredQueries transitively — do not add them separately.

### Implementation steps (each must compile before the next)

1. **Add SPM packages** via Xcode → File → Add Package Dependencies. Resolve.
2. **Create `AppState.swift`** (`App/AppState.swift`) with the `@Observable` class as sketched above.
3. **Create `StanisLoveTVApp.swift`** with the `@main` struct (remove from `ContentView.swift`).  
   Instantiate `AppState()` here and inject via `.environment(appState)`.
4. **Create `Spacing.swift`** and **`Typography.swift`** with the design constant enums from `tvos-ui.md`.
5. **Create `AppConstants.swift`** (`Core/Constants/AppConstants.swift`) with `playlistRefreshInterval` as shown above.
6. **Create `DependencyValues+.swift`** as an empty file with comment stubs for each future key.
7. **Create `RootView.swift`** with a four-tab `TabView`:  
   Channels / Guide / Playlists / Settings (all pointing to stub `Text("...")` views).  
   Reads `AppState` from environment: `@Environment(AppState.self) private var appState`.
8. **Gut `ContentView.swift`** — replace body with `RootView()` or delete file entirely and update `StanisLoveTVApp.swift` directly.

### Tests to write

None in this phase — no logic exists yet. Verify with `⌘B` (build only).

### tvOS notes

- `TabView` on tvOS renders as a horizontal tab bar at the top of the screen.
- Tab items use SF Symbols — choose ones that read well at 3 m.
- The tab bar auto-hides when focus moves into content; `.tabViewStyle(.sidebarAdaptable)` is NOT used on tvOS.

### Definition of Done

- Project builds cleanly with zero warnings on tvOS 27 simulator.
- Four-tab shell appears; each tab shows a placeholder string.
- `DependencyValues+.swift` is the single file for all future DI key extensions.

---

## Phase 2 — Domain Layer

**Goal**: Framework-free entities, repository protocols, and use case stubs. No SQLiteData, no AVFoundation, no SwiftUI. This layer compiles independently.

**Complexity**: S  
**Depends on**: Phase 1

### Files to create

| Path | Notes |
|------|-------|
| `StanisLoveTV/Domain/Entities/Channel.swift` | struct, Identifiable, Hashable, Sendable |
| `StanisLoveTV/Domain/Entities/Playlist.swift` | struct + `PlaylistType` enum; includes `epgURL: URL?` |
| `StanisLoveTV/Domain/Entities/EPGProgram.swift` | struct, Sendable |
| `StanisLoveTV/Domain/Entities/Category.swift` | struct wrapping `groupTitle: String`, `channelCount: Int` |
| `StanisLoveTV/Domain/Entities/AppError.swift` | `enum AppError: LocalizedError` |
| `StanisLoveTV/Domain/Entities/Mocks/Channel+Mock.swift` | `static func mock(...)` factory for tests |
| `StanisLoveTV/Domain/Entities/Mocks/Playlist+Mock.swift` | mock factory |
| `StanisLoveTV/Domain/Entities/Mocks/EPGProgram+Mock.swift` | mock factory |
| `StanisLoveTV/Domain/Repositories/ChannelRepository.swift` | protocol |
| `StanisLoveTV/Domain/Repositories/PlaylistRepository.swift` | protocol; includes `updateEPGURL(id:url:)` |
| `StanisLoveTV/Domain/Repositories/EPGRepository.swift` | protocol |
| `StanisLoveTV/Domain/Repositories/FavoriteRepository.swift` | protocol |
| `StanisLoveTV/Domain/UseCases/FetchChannelsUseCase.swift` | struct + DependencyKey |
| `StanisLoveTV/Domain/UseCases/FetchPlaylistsUseCase.swift` | struct + DependencyKey |
| `StanisLoveTV/Domain/UseCases/AddPlaylistUseCase.swift` | struct + DependencyKey |
| `StanisLoveTV/Domain/UseCases/DeletePlaylistUseCase.swift` | struct + DependencyKey |
| `StanisLoveTV/Domain/UseCases/RefreshPlaylistUseCase.swift` | struct + DependencyKey |
| `StanisLoveTV/Domain/UseCases/FetchEPGUseCase.swift` | struct + DependencyKey |
| `StanisLoveTV/Domain/UseCases/ToggleFavoriteUseCase.swift` | struct + DependencyKey |
| `StanisLoveTV/Domain/UseCases/SearchChannelsUseCase.swift` | struct + DependencyKey |

### Entity shapes

```swift
// Channel.swift
struct Channel: Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    let streamURL: URL
    let logoURL: URL?
    let groupTitle: String
    let tvgID: String?
    var isFavorite: Bool
}

// Playlist.swift
enum PlaylistType: String, Sendable, Codable { case m3u, m3uPlus }
struct Playlist: Identifiable, Sendable {
    let id: UUID
    let name: String
    let url: URL
    let type: PlaylistType
    var epgURL: URL?       // Optional; user may set manually or extracted from M3U header
    var lastUpdated: Date?
}

// EPGProgram.swift
struct EPGProgram: Identifiable, Sendable {
    let id: UUID
    let channelID: String
    let title: String
    let startTime: Date
    let endTime: Date
    let description: String?
}

// Category.swift
struct Category: Identifiable, Hashable, Sendable {
    var id: String { groupTitle }
    let groupTitle: String
    let channelCount: Int
}
```

### AppError cases

```swift
enum AppError: LocalizedError {
    case networkUnavailable
    case playbackFailed(String)
    case playlistParseError(String)
    case epgFetchFailed
    case streamURLInvalid
    case databaseError(String)
}
```

### Repository protocols (illustrative)

```swift
protocol ChannelRepository: Sendable {
    func fetchAll(playlistID: UUID) async throws -> [Channel]
    func fetchFavorites() async throws -> [Channel]
    func save(_ channels: [Channel], playlistID: UUID) async throws
    func search(query: String) async throws -> [Channel]
}

protocol PlaylistRepository: Sendable {
    func fetchAll() async throws -> [Playlist]
    func insert(_ playlist: Playlist) async throws
    func delete(id: UUID) async throws
    func updateLastFetched(id: UUID, date: Date) async throws
    func updateEPGURL(id: UUID, url: URL?) async throws
}

protocol EPGRepository: Sendable {
    func fetchPrograms(channelID: String, after: Date) async throws -> [EPGProgram]
    func replaceAll(channelID: String, programs: [EPGProgram]) async throws
    func pruneStale(olderThan: Date) async throws
}

protocol FavoriteRepository: Sendable {
    func fetchAll() async throws -> [UUID]
    func toggle(channelID: UUID) async throws -> Bool  // returns new isFavorite
}
```

### Use case pattern (all use cases follow this shape)

```swift
struct FetchChannelsUseCase {
    var execute: (UUID) async throws -> [Channel]
}
extension FetchChannelsUseCase: DependencyKey {
    static var liveValue: Self {
        .init { playlistID in
            @Dependency(\.channelRepository) var repo
            return try await repo.fetchAll(playlistID: playlistID)
        }
    }
    static let testValue = FetchChannelsUseCase(
        execute: { _ in unimplemented("FetchChannelsUseCase.execute") }
    )
}
extension DependencyValues {
    var fetchChannelsUseCase: FetchChannelsUseCase {
        get { self[FetchChannelsUseCase.self] }
        set { self[FetchChannelsUseCase.self] = newValue }
    }
}
```

All `DependencyValues` extensions go in `Core/Dependencies/DependencyValues+.swift`.

### New DependencyKey registrations (Phase 2)

- `channelRepository: any ChannelRepository`
- `playlistRepository: any PlaylistRepository`
- `epgRepository: any EPGRepository`
- `favoriteRepository: any FavoriteRepository`
- `fetchChannelsUseCase: FetchChannelsUseCase`
- `fetchPlaylistsUseCase: FetchPlaylistsUseCase`
- `addPlaylistUseCase: AddPlaylistUseCase`
- `deletePlaylistUseCase: DeletePlaylistUseCase`
- `refreshPlaylistUseCase: RefreshPlaylistUseCase`
- `fetchEPGUseCase: FetchEPGUseCase`
- `toggleFavoriteUseCase: ToggleFavoriteUseCase`
- `searchChannelsUseCase: SearchChannelsUseCase`

Repository `liveValue` will be filled in Phase 3. Leave as `unimplemented(...)` stubs for now.

### Tests to write

- `Tests/DomainTests/EntitiesTests.swift` — verify `Channel.mock()` produces expected fields; `isFavorite` starts `false`.
- No use case logic tests yet — live values have no implementation.

---

## Phase 3 — Database & Persistence Layer

**Goal**: SQLiteData `@Table` structs, `DatabaseStack`, migration v1 + v2, and `DefaultXxxRepository` implementations wired to `DependencyValues`.

**Complexity**: M  
**Depends on**: Phase 2  
**HIGH RISK**: Migration DDL — mistakes here require a new migration version; never edit `v1_initial` once shipped.

### Files to create

| Path | Notes |
|------|-------|
| `StanisLoveTV/Data/Persistence/DatabaseStack.swift` | `DatabaseStack` struct + `DependencyKey` |
| `StanisLoveTV/Data/Persistence/Migrations/Migrations.swift` | `Migrations.register(in:)` — registers v1 and v2 |
| `StanisLoveTV/Data/Persistence/Tables/PlaylistRecord.swift` | `@Table nonisolated struct` + `domainModel`; includes `epgURL: String?` |
| `StanisLoveTV/Data/Persistence/Tables/ChannelRecord.swift` | `@Table nonisolated struct` + `domainModel` |
| `StanisLoveTV/Data/Persistence/Tables/FavoriteRecord.swift` | `@Table nonisolated struct` |
| `StanisLoveTV/Data/Persistence/Tables/EPGProgramRecord.swift` | `@Table nonisolated struct` + `domainModel` |
| `StanisLoveTV/Data/Repositories/DefaultChannelRepository.swift` | implements `ChannelRepository` |
| `StanisLoveTV/Data/Repositories/DefaultPlaylistRepository.swift` | implements `PlaylistRepository`; handles `epgURL` field |
| `StanisLoveTV/Data/Repositories/DefaultEPGRepository.swift` | implements `EPGRepository` |
| `StanisLoveTV/Data/Repositories/DefaultFavoriteRepository.swift` | implements `FavoriteRepository` |

### UserDefaults keys added in this phase

| Key | Type | Purpose |
|-----|------|---------|
| `"epgLastFetchedAt"` | `Date` (ISO string) | EPG 24h TTL tracking |

> **DECISION (finalised)**: `activePlaylistID` is **NOT** managed by any repository in this phase. It lives exclusively in `AppState` (`App/AppState.swift`), which handles its own `UserDefaults` persistence in `didSet`. Repositories and use cases receive the resolved playlist ID as a parameter — they never read `UserDefaults["activePlaylistID"]` directly.
>
> If the stored UUID no longer matches any playlist in the DB (detected in `ChannelListViewModel.load()` or `DeletePlaylistUseCase`), `AppState.activePlaylistID` is set to `nil` (or to the first available playlist's ID) by the caller — not by the repository.

### SQLiteData Schema — Migration v1_initial

**Migration name**: `"v1_initial"`

```sql
-- playlists table (no epgURL yet — added in v2)
CREATE TABLE "playlists" (
    "id"          TEXT PRIMARY KEY NOT NULL DEFAULT (uuid()),
    "name"        TEXT NOT NULL DEFAULT '',
    "urlString"   TEXT NOT NULL,
    "lastFetched" TEXT
) STRICT;

-- channels table
CREATE TABLE "channels" (
    "id"         TEXT PRIMARY KEY NOT NULL DEFAULT (uuid()),
    "playlistID" TEXT NOT NULL REFERENCES "playlists"("id") ON DELETE CASCADE,
    "name"       TEXT NOT NULL DEFAULT '',
    "streamURL"  TEXT NOT NULL,
    "logoURL"    TEXT,
    "groupTitle" TEXT NOT NULL DEFAULT '',
    "tvgID"      TEXT,
    "position"   INTEGER NOT NULL DEFAULT 0
) STRICT;

-- favorites table
CREATE TABLE "favorites" (
    "id"      TEXT PRIMARY KEY NOT NULL,
    "addedAt" TEXT NOT NULL DEFAULT (datetime('now'))
) STRICT;

-- epgPrograms table
CREATE TABLE "epgPrograms" (
    "id"                 TEXT PRIMARY KEY NOT NULL DEFAULT (uuid()),
    "channelID"          TEXT NOT NULL,
    "title"              TEXT NOT NULL DEFAULT '',
    "startTime"          TEXT NOT NULL,
    "endTime"            TEXT NOT NULL,
    "programDescription" TEXT,
    "fetchedAt"          TEXT NOT NULL DEFAULT (datetime('now'))
) STRICT;

-- indexes
CREATE INDEX "idx_channels_playlistID"           ON "channels"    ("playlistID");
CREATE INDEX "idx_epgPrograms_channelID_start"   ON "epgPrograms" ("channelID", "startTime");
```

### SQLiteData Schema — Migration v2_playlist_epg_url

**Migration name**: `"v2_playlist_epg_url"`

```sql
ALTER TABLE "playlists" ADD COLUMN "epgURL" TEXT;
```

This column is `NULL` by default (no EPG URL configured).  
`PlaylistRecord` adds `var epgURL: String?`; `domainModel` maps it to `Playlist.epgURL: URL?` via `URL(string:)`.

**Column type notes**:
- `UUID` stored as `TEXT` (GRDB default for UUID).
- `Date` stored as `TEXT` ISO-8601 (GRDB default).
- `STRICT` mode enforced — type mismatch at insert = runtime error (good for catching bugs early).
- `ON DELETE CASCADE` on `channels.playlistID` — deleting a playlist wipes its channels atomically.

**Future migrations**: Any schema change gets a new `migrator.registerMigration("v3_...")` block. Never modify `v1_initial` or `v2_playlist_epg_url`.

### @Table structs (exact shape from persistence.md)

All four structs are `nonisolated struct`, all have `domainModel: Domain.Entity` computed var.  
`ChannelRecord.domainModel` sets `isFavorite: false`; the repository resolves favorites via a join or separate fetch and merges the flag before returning.

### Repository implementations

**`DefaultChannelRepository`**:
- `fetchAll(playlistID:)` — reads `ChannelRecord` ordered by `position`, maps to domain, cross-references `FavoriteRecord` to set `isFavorite`.
- `fetchFavorites()` — joins `channels` with `favorites` on `channels.id == favorites.id`.
- `save(_:playlistID:)` — deletes all rows for `playlistID`, bulk-inserts new rows in a single write transaction.
- `search(query:)` — `WHERE name LIKE '%\(query)%' OR groupTitle LIKE '%\(query)%'`.

**`DefaultPlaylistRepository`**:
- `updateEPGURL(id:url:)` — writes the `epgURL` column for an existing playlist row.

**`DefaultEPGRepository`**:
- `replaceAll(channelID:programs:)` — deletes existing rows for `channelID`, inserts new ones, prunes stale rows (fetchedAt < now - 172800s), all in one write transaction.
- `pruneStale(olderThan:)` — separate write, called from `EPGViewModel` if TTL logic warrants it.

### New DependencyKey registrations (Phase 3)

- `database: DatabaseStack` (both `liveValue` and `testValue` in `DatabaseStack.swift`)
- Wire `channelRepository`, `playlistRepository`, `epgRepository`, `favoriteRepository` `liveValue` to concrete `Default*Repository()`.

### Tests to write

`Tests/DataTests/RepositoryIntegrationTests.swift`:
```
@Test func insertsAndFetchesPlaylist()
@Test func deletingPlaylistCascadesToChannels()
@Test func channelFavoriteFlagResolvesCorrectly()
@Test func epgPrunesStaleRowsOnReplace()
@Test func searchReturnsMatchingChannels()
@Test func updateEPGURL_persists()
@Test func activePlaylistID_fallsBackToFirstOnDeletion()
```

Use in-memory `DatabaseStack(writer: try DatabaseQueue())` outside the `withDependencies` closure.

---

## Phase 4 — Networking & Parsers

**Goal**: `NetworkService` dependency, `M3UParser` (with `url-tvg` header extraction), `XMLTVParser`, file cache utility. All parsing on background `Task`.

**Complexity**: M  
**Depends on**: Phase 2  
**HIGH RISK**: XMLTV parsing — XMLTV is a large XML dialect with timezone offsets in `startTime`/`stopTime` attributes (`20241215120000 +0100`). Wrong date parsing silently produces incorrect EPG data.

### Files to create

| Path | Notes |
|------|-------|
| `StanisLoveTV/Data/Network/NetworkService.swift` | struct + DependencyKey |
| `StanisLoveTV/Data/Network/Endpoint.swift` | simple value type for URL + headers |
| `StanisLoveTV/Data/Parsers/M3UParser.swift` | value type; returns `M3UParseResult` (channels + optional EPG URL) |
| `StanisLoveTV/Data/Parsers/XMLTVParser.swift` | value type, `parse(_ data: Data) throws -> [EPGProgram]` |
| `StanisLoveTV/Data/Parsers/ParseError.swift` | `enum ParseError: Error` |
| `StanisLoveTV/Core/Utilities/FileCacheManager.swift` | read/write to `Caches` dir, exclude from backup |

### NetworkService

```swift
struct NetworkService {
    var fetchData: (URL) async throws -> Data
    var downloadToCache: (URL, filename: String) async throws -> URL
    var checkStreamHealth: (URL) async throws -> Bool  // HEAD request, 3s timeout
}
extension NetworkService: DependencyKey { ... }
extension DependencyValues {
    var networkService: NetworkService { ... }
}
```

`downloadToCache` uses `URLSession.shared.download(from:)` and moves the temp file to `Caches/StanisLoveTV/<filename>`.

### M3UParser

- Input: `String` (already loaded into memory or from file)
- Output: `M3UParseResult` — a value type containing `channels: [Channel]` and `epgURL: URL?`
- **EPG URL extraction**: on the first line (`#EXTM3U`), parse the `url-tvg="..."` attribute if present.  
  Example: `#EXTM3U url-tvg="https://example.com/epg.xml" x-tvg-url="..."` — use `url-tvg` (canonical) first; fall back to `x-tvg-url` if `url-tvg` is absent.  
  If neither attribute is present, `epgURL` is `nil`.
- Attribute extraction regex or manual split — handle both `key="value"` and `key=value` forms
- Validate `streamURL` at parse time: `URL(string:)` must succeed and scheme must be `http` or `https`
- `tvg-logo` → `URL?` (nil if malformed, not a fatal error)
- Malformed lines are skipped with a warning log (never throws)

```swift
struct M3UParseResult {
    let channels: [Channel]
    let epgURL: URL?   // Extracted from #EXTM3U url-tvg attribute, or nil
}
```

### XMLTVParser

- Uses `XMLParser` (Foundation) in callback style, wraps in `async` via continuation
- XMLTV timestamp format: `yyyyMMddHHmmss Z` (with space before timezone offset)
- Use `DateFormatter` with `en_US_POSIX` locale, format `"yyyyMMddHHmmss Z"`
- One `EPGProgram` per `<programme>` element
- `channel` attribute → `EPGProgram.channelID`
- Ignore `<channel>` elements (EPG channel metadata) — only parse `<programme>` elements
- Parse `<title>` and `<desc>` child elements
- HIGH RISK: timezone offset must be parsed correctly. Test with `+0000`, `+0100`, `-0500` offsets.

### FileCacheManager

```swift
struct FileCacheManager {
    var cacheDirectory: () throws -> URL
    var writeData: (Data, filename: String) throws -> URL
    var readData: (filename: String) throws -> Data
    var fileExists: (String) -> Bool
    var deleteFile: (String) throws -> Void
}
```

Cache files are stored in `FileManager.default.urls(for: .cachesDirectory, ...)`.  
Each file created with `.isExcludedFromBackupKey = true` resource value.

### New DependencyKey registrations (Phase 4)

- `networkService: NetworkService`
- `fileCacheManager: FileCacheManager`
- `m3uParser: M3UParser` (if making it a dependency; otherwise just a value type called directly)
- `xmltvParser: XMLTVParser`

### Tests to write

`Tests/DataTests/M3UParserTests.swift`:
```
@Test func parseValidM3U_singleChannel()
@Test func parseValidM3U_multipleChannels()
@Test func parseExtractsAllAttributes()
@Test func malformedLineIsSkippedNotFatal()
@Test func missingExtm3uHeader_returnsEmpty()
@Test func invalidStreamURL_channelSkipped()
@Test func groupTitleWithCommaInName_parsedCorrectly()
@Test func parseM3UHeader_extractsUrlTvgAttribute()
@Test func parseM3UHeader_extractsFallbackXTvgUrl()
@Test func parseM3UHeader_noEPGAttribute_returnsNilEpgURL()
```

`Tests/DataTests/XMLTVParserTests.swift`:
```
@Test func parseValidXMLTV_singleProgram()
@Test func parseXMLTV_timezoneUTC()
@Test func parseXMLTV_timezonePositiveOffset()
@Test func parseXMLTV_timezoneNegativeOffset()
@Test func parseXMLTV_missingDesc_producesNilDescription()
@Test func parseXMLTV_malformedTimestamp_isSkipped()
```

Coverage target: 90%+ for both parsers.

---

## Phase 5 — M3U Playlist Management

**Goal**: Users can add a playlist URL (with optional EPG URL), trigger a fetch + parse, see channels stored in DB. Delete a playlist wipes its channels. Auto-refresh triggers on app foreground.

**Complexity**: L  
**Depends on**: Phases 3, 4

### Files to create

| Path | Notes |
|------|-------|
| `StanisLoveTV/Domain/UseCases/AddPlaylistUseCase.swift` | validate URL, insert playlist, fetch + parse, save channels, extract & store EPG URL |
| `StanisLoveTV/Domain/UseCases/RefreshPlaylistUseCase.swift` | re-fetch + re-parse for existing playlist |
| `StanisLoveTV/Domain/UseCases/DeletePlaylistUseCase.swift` | delete playlist (cascade handles channels); update `activePlaylistID` if deleted playlist was active |
| `StanisLoveTV/Presentation/Playlists/PlaylistsViewModel.swift` | `@MainActor @Observable` |
| `StanisLoveTV/Presentation/Playlists/PlaylistsView.swift` | List of playlists + Add button |
| `StanisLoveTV/Presentation/Playlists/AddPlaylistView.swift` | URL input sheet with optional EPG URL field |

### AddPlaylistUseCase flow

```
1. Validate M3U URL format → throw AppError.streamURLInvalid if bad
2. Insert Playlist record (status: pending; epgURL: nil initially)
3. Download M3U file to cache via networkService.downloadToCache
4. Parse text via M3UParser.parse(_:) → M3UParseResult
5. EPG URL resolution (priority order):
   a. If user provided a manual EPG URL in AddPlaylistView → use it
   b. Else if M3UParseResult.epgURL != nil → use extracted url-tvg value
   c. Else → leave epgURL nil on the playlist
6. Persist resolved epgURL via playlistRepository.updateEPGURL(id:url:)
7. Save [Channel] via channelRepository.save(_:playlistID:)
8. Update playlist.lastFetched
9. Return updated Playlist
```

All of steps 3–8 run on a background `Task` (not `@MainActor`). The ViewModel switches back to `@MainActor` for state updates.

### RefreshPlaylistUseCase flow

Re-fetches and re-parses the M3U for an existing playlist. EPG URL is NOT re-extracted on refresh (user setting wins; to change the EPG URL the user edits the playlist in Settings). Steps 3–5 (download, parse, save channels, update `lastFetched`).

Called from:
- Settings screen "Refresh" button (explicit user action).
- **App foreground trigger** — `RefreshPlaylistUseCase` is called for the active playlist when the app becomes active.

### App Foreground Auto-Refresh

The foreground refresh is wired in the app root view using `ScenePhase`:

```swift
// In RootView.swift
@Environment(\.scenePhase) private var scenePhase

var body: some View {
    TabView { ... }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { await appViewModel.refreshActivePlaylistIfNeeded() }
            }
        }
}
```

`AppViewModel` (or `PlaylistsViewModel`) holds `refreshActivePlaylistIfNeeded()` which:
1. Reads `activePlaylistID` from `AppState` (passed via init or `@Environment`).
2. Calls `refreshPlaylistUseCase.execute(id:)` for that playlist.
3. Throttles: skips refresh if `lastFetched` is less than `AppConstants.playlistRefreshInterval` (15 minutes) ago.

This avoids hammering the server on every focus switch while still keeping data fresh.

### PlaylistsViewModel

```swift
@MainActor @Observable final class PlaylistsViewModel {
    var playlists: [Playlist] = []
    var isLoading = false
    var error: AppError?
    var showAddSheet = false

    @ObservationIgnored @Dependency(\.fetchPlaylistsUseCase) private var fetchPlaylists
    @ObservationIgnored @Dependency(\.addPlaylistUseCase) private var addPlaylist
    @ObservationIgnored @Dependency(\.deletePlaylistUseCase) private var deletePlaylist
    @ObservationIgnored @Dependency(\.refreshPlaylistUseCase) private var refreshPlaylist

    func load() async { ... }
    func add(url: URL, name: String, epgURL: URL?) async { ... }
    func delete(id: UUID) async { ... }
    func refresh(id: UUID) async { ... }
}
```

### AddPlaylistView (tvOS-specific concerns)

- Two input fields: **M3U URL** (required) and **EPG URL** (optional, labelled "EPG/XMLTV URL (optional)").
- Both use `TextField` with `.keyboardType(.URL)`.
- Focus the M3U URL text field automatically on sheet appear: `@FocusState` + `.onAppear`.
- Confirm button is the primary action; cancel button dismisses. Both must be focusable.
- Show a `ProgressView` overlay while the add is in progress.
- `.onExitCommand` on the sheet dismisses it (Menu button behavior).
- Helper text below the EPG field: "Leave blank to auto-detect from playlist header."

### Tests to write

`Tests/DomainTests/AddPlaylistUseCaseTests.swift`:
```
@Test func addPlaylist_validURL_insertsAndFetchesChannels()
@Test func addPlaylist_invalidURL_throwsStreamURLInvalid()
@Test func addPlaylist_networkFailure_doesNotInsertPlaylist()
@Test func addPlaylist_manualEPGURL_takesHighestPriority()
@Test func addPlaylist_noManualEPG_extractsFromHeader()
@Test func addPlaylist_noEPGAnywhere_leavesEPGURLNil()
@Test func refreshPlaylist_replacesChannels()
@Test func refreshPlaylist_doesNotOverwriteManualEPGURL()
@Test func deletePlaylist_removesFromDB()
@Test func deletePlaylist_clearsActivePlaylistIDIfMatch()
```

`Tests/PresentationTests/PlaylistsViewModelTests.swift`:
```
@Test func load_populatesPlaylists()
@Test func add_appendsToList()
@Test func delete_removesFromList()
@Test func error_isSetOnFailure()
@Test func foregroundRefresh_skippedIfFetchedRecently()
@Test func foregroundRefresh_triggeredWhenStale()
```

---

## Phase 6 — Channel Browser

**Goal**: Channels tab shows channels grouped by `groupTitle` for the **currently active playlist**. Search filters inline. Channel card shows logo (Kingfisher), name, group. Selecting a channel opens the player.

**Complexity**: L  
**Depends on**: Phase 5

### Files to create

| Path | Notes |
|------|-------|
| `StanisLoveTV/Presentation/Channels/ChannelListViewModel.swift` | `@MainActor @Observable`; receives `AppState` via init; observes `appState.activePlaylistID` |
| `StanisLoveTV/Presentation/Channels/ChannelListView.swift` | Main channels tab |
| `StanisLoveTV/Presentation/Channels/ChannelCardView.swift` | 300×170 pt card with logo + name |
| `StanisLoveTV/Presentation/Channels/CategorySidebarView.swift` | Left sidebar list of groups |
| `StanisLoveTV/Presentation/Channels/ChannelSearchView.swift` | Search results overlay |

### Active Playlist Loading

`ChannelListViewModel` receives `AppState` via its initialiser:

```swift
init(appState: AppState) { self.appState = appState }
```

`ChannelListViewModel.load()`:
1. Read `appState.activePlaylistID`.
2. If nil, fetch the first playlist from `playlistRepository.fetchAll()` and set `appState.activePlaylistID` to its ID (this is the only place the fallback auto-assignment happens — and only when truly no active ID is stored).
3. If no playlists exist at all, show the "No playlists" empty state.
4. Fetch channels for the resolved playlist ID via `fetchChannelsUseCase.execute(playlistID:)`.

Channels shown in the browser are scoped to the single active playlist. If the user switches the active playlist in Settings (which writes `appState.activePlaylistID`), `@Observable` triggers a re-render automatically — no `Notification.Name` needed.

Duplicate channels from separate playlists are never merged — they appear as separate entries when each playlist is active.

### ChannelListViewModel

```swift
@MainActor @Observable final class ChannelListViewModel {
    var channels: [Channel] = []
    var categories: [Category] = []
    var selectedCategory: Category?
    var searchQuery: String = ""
    var searchResults: [Channel] = []
    var isLoading = false
    var error: AppError?

    @ObservationIgnored private let appState: AppState
    @ObservationIgnored @Dependency(\.fetchChannelsUseCase) private var fetchChannels
    @ObservationIgnored @Dependency(\.searchChannelsUseCase) private var searchChannels

    init(appState: AppState) {
        self.appState = appState
    }

    var filteredChannels: [Channel] {
        guard let cat = selectedCategory else { return channels }
        return channels.filter { $0.groupTitle == cat.groupTitle }
    }

    func load() async { ... }   // reads appState.activePlaylistID; falls back to first playlist if nil
    func search() async { ... } // debounced via Task + Task.sleep
}
```

### ChannelCardView (tvOS-specific concerns)

- Size: `TVSize.channelCardWidth × TVSize.channelCardHeight` (300×170 pt).
- Logo loaded via `KFImage(channel.logoURL)` with `.placeholder { Image(systemName: "tv") }`.
- Focus scale: `1.1` on focus, `1.0` at rest, `.easeInOut(0.15)`.
- `accessibilityLabel`: `"\(channel.name), \(channel.groupTitle)"`.
- `accessibilityHint`: `"Press to play"`.
- `accessibilityAddTraits(.isButton)`.

### CategorySidebarView (tvOS-specific concerns)

- `List` on the left, channels `LazyVGrid` or `LazyHStack` on the right.
- Use `.focusSection()` on both sidebar and content area to allow D-pad traversal between them.
- "All Channels" at the top of the sidebar clears the category filter.
- Sidebar minimum width: 300 pt.

### Layout

```
┌─────────────────────────────────────────────────────┐
│ [Search]                              Channels Tab   │
├──────────────┬──────────────────────────────────────┤
│ All Channels │  [Card][Card][Card][Card][Card]       │
│ UK           │  [Card][Card][Card][Card][Card]       │
│ Sports       │  [Card][Card]                        │
│ Movies       │                                      │
└──────────────┴──────────────────────────────────────┘
```

Use `HStack` with a sidebar `List` (fixed width) and a `ScrollView { LazyVGrid }` for channels.

### SearchChannelsUseCase

```swift
struct SearchChannelsUseCase {
    var execute: (String) async throws -> [Channel]
}
// liveValue: calls channelRepository.search(query:)
```

### Tests to write

`Tests/PresentationTests/ChannelListViewModelTests.swift`:
```
@Test func load_populatesChannelsAndCategories()
@Test func load_usesActivePlaylistIDFromUserDefaults()
@Test func load_fallsBackToFirstPlaylistWhenNoActiveIDSet()
@Test func load_showsEmptyStateWhenNoPlaylists()
@Test func filteredChannels_filtersBySelectedCategory()
@Test func search_returnsMatchingChannels()
@Test func search_emptyQuery_returnsNothing()
@Test func error_isSetWhenFetchFails()
```

---

## User Flow & Navigation Spec

**Написано**: после Phase 6, перед Phase 7. Закрывает Decision #4 (переключение каналов в плеере), описывает все переходы между экранами сквозным образом и вскрывает один дефект в реализации Phase 6, который нужно исправить до того, как Phase 7/8/10 смогут полагаться на распространение `AppState`, как это задумано.

### Карта экранов

```
RootView (TabView, 4 tabs)
├── Channels   (ChannelListView)        — Phase 6, готово
├── Guide      (EPGView)                 — Phase 8, заглушка
├── Playlists  (PlaylistsView)           — Phase 5, готово (CRUD + индикатор активного)
└── Settings   (SettingsView)            — Phase 10, заглушка

Full-screen cover (поверх любой вкладки): Player  — Phase 7
Sheets: AddPlaylistView (вкладка Playlists), EditPlaylistView (вкладка Settings, Phase 10)
```

**Уточнение зон ответственности вкладок** (сужает скоуп Phase 10): вкладка Playlists уже владеет CRUD-операциями над плейлистами и индикатором-галочкой активного плейлиста (сделано в Phase 5). Изначальная спецификация Phase 10 дублировала это на вкладке Settings. **Решение**: вкладка Settings НЕ дублирует список плейлистов. Она отвечает только за: жест "тап — сделать активным" на существующей вкладке Playlists (нужно добавить недостающий жест — сегодня галочка чисто отображается, ничего не устанавливает `appState.activePlaylistID` по действию пользователя), редактирование EPG URL для каждого плейлиста, очистку кэша и раздел About. Список файлов Phase 10 нужно будет пересмотреть, когда эта фаза будет реально планироваться.

### Дефект, найденный при трассировке этих флоу (исправить до Phase 7)

Сейчас в `RootView.swift`:
```swift
.task { await channelListViewModel.load() }
```
Обычный `.task` выполняется один раз за жизненный цикл view. Он **не** перезапускается, когда `appState.activePlaylistID` меняется позже (например, пользователь активировал другой плейлист). Это противоречит утверждению из плана Phase 6 и Decision #6 о том, что распространение через `@Observable` происходит автоматически — `@Observable` вызывает повторный рендер только того кода, который *читает* свойство внутри body view; он не перезапускает уже завершившийся `.task`. Конкретно: добавить плейлист на вкладке Playlists (первый плейлист → авто-активация), переключиться на вкладку Channels — сегодня там всё ещё может показываться устаревшее "No Playlists" до перезапуска приложения, поскольку view вкладок остаются живыми при переключении между вкладками.

**Необходимое исправление**: `.task(id: appState.activePlaylistID) { await channelListViewModel.load() }`. Тот же паттерн понадобится для `EPGViewModel` в Phase 8. Это однострочная правка в `RootView.swift`, зафиксированная здесь, чтобы не забыть; внести можно когда угодно до того, как от этого поведения начнут зависеть Phase 8/10 (самой Phase 7 это не нужно, поскольку плеер владеет отвязанным снэпшотом — см. Flow 7).

**Обновление**: формализовано и закрыто в Phase 6.5 → Шаг 1 (см. ниже, после Flow 9).

### Flow 1 — Холодный старт / онбординг (нет плейлистов)

1. Приложение запускается → `AppState.init()` читает `activePlaylistID` из `UserDefaults` (nil при чистой установке).
2. `RootView` монтируется; `.task` всех вкладок запускаются параллельно.
3. Вкладка Channels: `load()` видит nil → запрашивает плейлисты → пусто → "No Playlists" `ContentUnavailableView` (на момент написания этого раздела — текстовый CTA без deep link; Open Question #1 из Phase 6 **закрыт в Phase 6.5**: CTA программно переключает `TabView` на вкладку Playlists — см. Phase 6.5 → Шаг 2).
4. Вкладка Guide (Phase 8): такое же пустое состояние, такая же текстовая подсказка.
5. Вкладка Playlists: своё собственное "No Playlists" пустое состояние **с рабочей кнопкой "Add Playlist"** — сегодня это единственная действующая точка входа.
6. Пользователь добавляет плейлист → `PlaylistsViewModel.add()` устанавливает `appState.activePlaylistID` (было nil) → после того как исправление выше будет внесено, Channels/Guide подхватят это автоматически при следующем фокусе; до этого момента им нужен перезапуск.

### Flow 2 — Просмотр и воспроизведение (happy path)

1. Вкладка Channels рендерит сетку для активного плейлиста.
2. D-pad перемещает фокус между `CategorySidebarView` (`.focusSection()`) и сеткой (`.focusSection()`); карточки увеличиваются при фокусе.
3. Выбор категории фильтрует `filteredChannels`; фильтр **эфемерный** — не сохраняется, сбрасывается на "All Channels" при следующем холодном старте.
4. Выбор карточки канала устанавливает `viewModel.selectedChannel` → `.fullScreenCover` открывает Player с:
   - выбранным `Channel`
   - **контекстом воспроизведения (play context)**: упорядоченным массивом, из которого была выбрана карточка (`filteredChannels` на момент тапа) — это становится списком для серфинга Next/Previous (см. Flow 3).
5. Кнопка Menu закрывает cover → возвращает на вкладку Channels ровно в том состоянии, в котором она была (позиция прокрутки, фокус, фильтр категории — ничего не разрушается, поскольку `ChannelListView`/`ViewModel` не пересоздаются при показе cover поверх них).

### Flow 3 — Переключение каналов внутри плеера (закрывает Decision #4)

**Решение**: реализовать переключение каналов Next/Previous в Phase 7, больше не откладывать. Данные, которые для этого нужны (упорядоченный массив `[Channel]`), уже есть на каждом экране, который может запустить плеер — дальнейшая отсрочка означала бы повторный пересмотр сигнатуры запуска плеера ещё раз позже.

- **Контекст воспроизведения (play context)** = упорядоченный `[Channel]` + стартовый индекс, захватывается один раз при запуске:
  - Из сетки Channels → `filteredChannels` (учитывает активный фильтр по категории/избранному)
  - Из результатов поиска → `searchResults`
  - Из Guide (Phase 8) → все каналы, отрендеренные в данный момент в таймлайне, в порядке строк
- Доступно через `transportBarCustomMenuItems` как "Next Channel" / "Previous Channel".
- `PlayerViewModel.switchChannel(direction:)`: вычисляет следующий индекс с **переходом по кругу** (последний → первый, первый → последний — непрерывный "серфинг каналов", соответствует ожиданиям от физического пульта), разрушает текущий `AVPlayerItem`, загружает новый поток, сбрасывает `retryCount` в 0, обновляет `customInfoViewController` (сейчас — название/лого канала; текущая EPG-программа — после выхода Phase 8).
- Если в контексте воспроизведения ровно 1 канал (например, будущая точка входа с единственным каналом), пункты меню Next/Previous скрываются, а не просто становятся неактивными.
- Добавление/удаление канала из избранного, пока плеер открыт, **не** мутирует уже захваченный массив контекста воспроизведения — он захвачен по значению при запуске.

### Flow 4 — Поиск → воспроизведение

1. Ввод 2+ символов в строке поиска на вкладке Channels запускает уже существующий поиск с debounce 300мс, ограниченный активным плейлистом.
2. Выбор результата открывает Player с контекстом воспроизведения = текущий массив `searchResults` (серфинг Next/Previous остаётся в пределах того, что показано на экране — принцип наименьшего удивления).
3. Выход из плеера возвращает на вкладку Channels с сохранёнными запросом и результатами.

### Flow 5 — Guide → воспроизведение (зависимость от Phase 8, спроектировано сейчас)

1. Пользователь прокручивает таймлайн EPG по горизонтали для каждой строки канала.
2. Выбор **любой** ячейки программы — идущей сейчас или будущей — сразу переключает на живой поток этого канала. В скоупе нет ни перемотки, ни напоминаний/записи; ячейка будущей программы носит чисто информационный характер, её выбор всё равно просто включает канал вживую.
3. Контекст воспроизведения = все каналы, отрендеренные в гиде в данный момент (порядок строк сверху вниз), поэтому Next/Previous ведёт себя так же, как из сетки.
4. Выход из плеера возвращает в Guide с сохранённой позицией прокрутки.

### Flow 6 — Избранное (Phase 9, спроектировано сейчас)

1. Кнопка-сердечко на `ChannelCardView` (используется как есть в сетке Channels, результатах поиска и строках Guide) переключает избранное оптимистично, затем сохраняет через `ToggleFavoriteUseCase`.
2. Избранное моделируется как **синтетический пункт в `CategorySidebarView`**, закреплённый под "All Channels" — его выбор фильтрует `filteredChannels` по `channel.isFavorite == true`. Используется тот же самый механизм фильтрации по категориям; отдельный экран или режим выбора не нужен.
3. Transport bar плеера **не** получает переключатель избранного в Phase 9 — оставлено вне скоупа, чтобы не наслаивать сразу два новых элемента transport bar (Next/Previous и Favorite) поверх и без того рискованной работы над плеером.

### Flow 7 — Смена активного плейлиста (вкладка Playlists/Settings)

1. Пользователь тапает по неактивному ряду плейлиста, чтобы сделать его активным (Phase 10 добавляет недостающий жест; сегодня ряд только отображает индикатор).
2. `appState.activePlaylistID` меняется → `AppState.didSet` сохраняет значение в `UserDefaults`.
3. Channels/Guide перезагружаются после того, как исправление дефекта выше будет внесено.
4. **Если Player сейчас открыт** и воспроизводит канал из *предыдущего* активного плейлиста: переключение активного плейлиста в другом месте **не** прерывает воспроизведение. Плеер владеет отвязанным снэпшотом (значение `Channel` + уже загруженный `AVPlayer` item) без живой привязки к `AppState`. Сетка Channels отразит новый активный плейлист только после того, как плеер будет закрыт и вкладка перезагрузится.
5. **Граничный случай** — удаление плейлиста, которому принадлежит воспроизводимый сейчас канал: `DeletePlaylistUseCase` каскадно удаляет каналы через FK, но на воспроизведение это не влияет (URL потока уже разрешён и хранится в памяти, повторного запроса к БД не происходит). Next/Previous внутри всё ещё открытого плеера продолжает работать с контекстом воспроизведения в памяти, пока плеер не будет закрыт. Специальной обработки не требуется.

### Flow 8 — Ошибки и retry во всех флоу

1. Сбой потока во время воспроизведения → существующий дизайн retry из Phase 7 (3 попытки с экспоненциальной задержкой, 1с/2с/4с) → `PlayerErrorView` с кнопками Retry/Exit.
2. Выход после исчерпанных попыток возвращает на тот экран, откуда был запущен плеер (Channels, Search или Guide), состояние сохраняется — принудительной перезагрузки нет.
3. Сетевые сбои при просмотре (Channels/Guide) используют существующий паттерн `.alert`; Phase 11 дополнительно указывает, что Guide показывает устаревшие, но видимые данные EPG при сбое загрузки, а не блокирует UI.

### Flow 9 — Уход в фон / возврат на передний план во время воспроизведения

1. При `scenePhase != .active`, пока Player открыт, `PlayerViewModel` ставит воспроизведение на паузу (`.onChange(of: scenePhase)` в `PlayerView`) — приложения tvOS по умолчанию не получают системный PiP, поэтому продолжение стрима в фоне просто расходует трафик без видимой пользы.
2. Возврат на передний план **не** возобновляет воспроизведение автоматически — пользователь нажимает Play/Pause на системном transport bar. Автовозобновление звука при возврате на передний план стало бы неожиданным; требование явного нажатия соответствует ожиданиям tvOS HIG.
3. Существующее фоновое обновление плейлиста раз в 15 минут (`refreshActivePlaylistIfNeeded()`) никогда не должно затрагивать уже захваченный контекст воспроизведения уже запущенного `PlayerViewModel` — это гарантируется дизайном отвязанного снэпшота из Flow 7, нового кода не требуется, здесь это лишь явно задокументированная гарантия.

---

## Phase 6.5 — End-to-End Onboarding → Playback Flow (сквозной happy path)

**Написано**: после «User Flow & Navigation Spec» (см. выше), перед Phase 7. Цель — дать владельцу продукта пройти весь пользовательский путь руками в симуляторе (пустое состояние → добавление плейлиста → список каналов → воспроизведение) прямо сейчас, не дожидаясь полноценной XL-фазы плеера. Формализует и закрывает три конкретные находки из Phase 6 / «User Flow & Navigation Spec»: дефект `.task` в `RootView.swift`, тупиковый CTA пустого состояния на вкладке Channels (Open Question #1 из Phase 6) и отсутствие вообще какого-либо экрана воспроизведения (сейчас там временная заглушка `Text("Playing: \(channel.name)")` в `ChannelListView.swift`).

**Complexity**: S  
**Depends on**: Phase 6 (Channel Browser)  
**Сознательно вне скоупа** (остаётся в Phase 7 — см. «User Flow & Navigation Spec → Flow 3» и Phase 7 ниже): retry/backoff, `EPGInfoViewController`, `transportBarCustomMenuItems` (Next/Previous), обработка `playbackState == .error`. Эта фаза даёт самый простой рабочий видеоплеер — «воспроизводит поток и ничего больше».

### Files to create / modify

| Path | Action |
|------|--------|
| `StanisLoveTV/App/RootView.swift` | Modify — `.task` → `.task(id: appState.activePlaylistID)`; добавить `AppTab` enum + `@State private var selectedTab` для программного переключения вкладок |
| `StanisLoveTV/Presentation/Channels/ChannelListView.swift` | Modify — добавить параметр `onNavigateToPlaylists: () -> Void`; кнопка в пустом состоянии "No Playlists"; заменить заглушку `fullScreenCover` на настоящий `PlayerView` |
| `StanisLoveTV/Presentation/Player/PlayerViewModel.swift` | Create — минимальная версия: держит `channel` + `AVPlayer`, без retry/backoff/EPG. **Phase 7 расширит этот же файл, не создаст новый.** |
| `StanisLoveTV/Presentation/Player/VideoPlayerView.swift` | Create — `UIViewControllerRepresentable`, оборачивает голый `AVPlayerViewController`. **Phase 7 модифицирует этот же файл.** |
| `StanisLoveTV/Presentation/Player/PlayerView.swift` | Create — SwiftUI-обёртка с `.onExitCommand` / `.onPlayPauseCommand`. **Phase 7 модифицирует этот же файл.** |
| `Tests/PresentationTests/PlayerViewModelTests.swift` | Create — 2 минимальных теста. **Phase 7 добавит тесты retry/backoff в этот же файл, не создаст новый.** |

### Шаг 1 — Исправить дефект `.task` в RootView.swift

Дефект уже описан в разделе «User Flow & Navigation Spec → Дефект, найденный при трассировке этих флоу» выше. Здесь он формализуется как первый шаг реализации.

```swift
// Было (MainTabView.body):
.task { await channelListViewModel.load() }

// Стало:
.task(id: appState.activePlaylistID) { await channelListViewModel.load() }
```

**Важный нюанс, вскрытый при подготовке этой фазы**: сегодня `MainTabView` не хранит `AppState` напрямую — он только принимается в `init(appState:)` и пробрасывается в дочерние `@State`-вьюмодели (`PlaylistsViewModel(appState:)`, `ChannelListViewModel(appState:)`). Чтобы модификатор `.task(id:)` мог читать `appState.activePlaylistID` в `body`, `MainTabView` должен сам держать ссылку на `AppState`. Так как `RootView` уже читает `AppState` из окружения (`@Environment(AppState.self) private var appState`) и передаёт его в `MainTabView.init`, самый простой и не создающий второго источника истины вариант — добавить `@Environment(AppState.self) private var appState` и в саму `MainTabView` (оба обращения указывают на один и тот же инстанс, инжектированный один раз в `StanisLoveTVApp`):

```swift
private struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab: AppTab = .channels
    @State private var playlistsViewModel: PlaylistsViewModel
    @State private var channelListViewModel: ChannelListViewModel

    init(appState: AppState) {
        _playlistsViewModel = State(wrappedValue: PlaylistsViewModel(appState: appState))
        _channelListViewModel = State(wrappedValue: ChannelListViewModel(appState: appState))
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            ChannelListView(
                viewModel: channelListViewModel,
                onNavigateToPlaylists: { selectedTab = .playlists }
            )
            .tabItem { Label("Channels", systemImage: "play.tv") }
            .tag(AppTab.channels)

            EPGView()
                .tabItem { Label("Guide", systemImage: "calendar") }
                .tag(AppTab.guide)

            PlaylistsView(viewModel: playlistsViewModel)
                .tabItem { Label("Playlists", systemImage: "list.bullet") }
                .tag(AppTab.playlists)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
                .tag(AppTab.settings)
        }
        .task(id: appState.activePlaylistID) { await channelListViewModel.load() }
        .task { await playlistsViewModel.load() }
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            await playlistsViewModel.refreshActivePlaylistIfNeeded()
        }
    }
}

enum AppTab: Hashable {
    case channels, guide, playlists, settings
}
```

Тот же паттерн (`.task(id: appState.activePlaylistID)`) в дальнейшем понадобится `EPGViewModel` в Phase 8 — уже отмечено в Decision #6.

### Шаг 2 — CTA пустого состояния переключает вкладку (закрывает Open Question #1 из Phase 6)

`ChannelListView` получает замыкание навигации через `init`, а не через `AppState` или ViewModel — это чисто UI-уровневая навигация, а не бизнес-логика, поэтому она не нарушает правило «никакой бизнес-логики во View» и не заставляет `ChannelListViewModel` знать о `TabView`/`AppTab`:

```swift
struct ChannelListView: View {
    @Bindable var viewModel: ChannelListViewModel
    var onNavigateToPlaylists: () -> Void = {}

    // ...existing body unchanged...

    @ViewBuilder
    private var emptyStateView: some View {
        if viewModel.hasActivePlaylists {
            ContentUnavailableView(
                "No Channels",
                systemImage: "tv.slash",
                description: Text("No channels found. Try refreshing the playlist in Settings.")
            )
        } else {
            ContentUnavailableView {
                Label("No Playlists", systemImage: "list.bullet.rectangle")
            } description: {
                Text("Add a playlist to get started.")
            } actions: {
                Button("Go to Playlists", action: onNavigateToPlaylists)
            }
        }
    }
}
```

Кнопка должна быть достижима фокусом пульта (стандартная `Button` внутри `ContentUnavailableView` на tvOS фокусируема без дополнительной работы).

### Шаг 3 — Минимальный видеоплеер (заменяет заглушку `Text("Playing: ...")`)

```swift
// Presentation/Player/PlayerViewModel.swift
import AVFoundation
import Observation

@MainActor
@Observable
final class PlayerViewModel {
    let channel: Channel
    let player: AVPlayer

    init(channel: Channel) {
        self.channel = channel
        self.player = AVPlayer(url: channel.streamURL)
    }

    func play() { player.play() }
    func togglePlayback() { player.rate == 0 ? player.play() : player.pause() }
    func stop() { player.pause() }
}
```

```swift
// Presentation/Player/VideoPlayerView.swift
import AVKit
import SwiftUI

struct VideoPlayerView: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = true
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}
```

```swift
// Presentation/Player/PlayerView.swift
import SwiftUI

struct PlayerView: View {
    @State private var viewModel: PlayerViewModel
    let onDismiss: () -> Void

    init(channel: Channel, onDismiss: @escaping () -> Void) {
        _viewModel = State(wrappedValue: PlayerViewModel(channel: channel))
        self.onDismiss = onDismiss
    }

    var body: some View {
        VideoPlayerView(player: viewModel.player)
            .ignoresSafeArea()
            .onAppear { viewModel.play() }
            .onDisappear { viewModel.stop() }
            .onExitCommand { onDismiss() }
            .onPlayPauseCommand { viewModel.togglePlayback() }
    }
}
```

Wiring in `ChannelListView.swift` (replaces the `Text("Playing: ...")` placeholder):

```swift
.fullScreenCover(item: $viewModel.selectedChannel) { channel in
    PlayerView(channel: channel, onDismiss: { viewModel.selectedChannel = nil })
}
```

`AVPlayer` создаётся строго внутри `PlayerViewModel.init`, не во View struct — соответствует anti-pattern правилу из `CLAUDE.md`.

### Явное отношение к Phase 7 (чтобы не было дублирования работы / конфликтов файлов)

Phase 7 **модифицирует**, а не создаёт с нуля:
- `PlayerViewModel.swift` — добавит `currentProgram`, `playbackState: PlaybackState`, `retryCount`/`retryTask`, `@ObservationIgnored @Dependency(\.networkService)`, `@ObservationIgnored @Dependency(\.fetchEPGUseCase)`, методы `startPlayback()` / `retry()` / `handleBack()`. Прямое владение `AVPlayer` может остаться как есть, либо быть делегировано новому `PlayerRepository`/`DefaultPlayerRepository` — это решается по месту в Phase 7 и не блокирует эту фазу; оба варианта совместимы с этим минимальным скелетом.
- `VideoPlayerView.swift` — добавит `controller.customInfoViewController = EPGInfoViewController(...)` и зарезервирует `transportBarCustomMenuItems` для Next/Previous.
- `PlayerView.swift` — добавит ветку `playbackState == .error` → `PlayerErrorView` оверлей.
- `Tests/PresentationTests/PlayerViewModelTests.swift` — тот же файл получает новые `@Test` для retry/backoff поверх двух тестов, написанных в этой фазе.

Phase 7 по-прежнему **создаёт с нуля**, без изменений в скоупе: `Domain/Repositories/PlayerRepository.swift`, `Data/Player/DefaultPlayerRepository.swift`, `Data/Player/StreamHealthChecker.swift`, `Presentation/Player/EPGInfoViewController.swift`, `Presentation/Player/PlayerErrorView.swift`.

### Dependency Registration

Нет новых `DependencyKey` в этой фазе — `AVPlayer` создаётся напрямую в `PlayerViewModel.init`, без сетевого слоя или репозитория. `PlayerRepository`/`DefaultPlayerRepository` (с DI-регистрацией) появятся в Phase 7 вместе с retry-логикой.

### tvOS considerations

- `.onExitCommand` на `PlayerView` закрывает `fullScreenCover` (кнопка Menu) — обязательное правило из `CLAUDE.md`.
- `.onPlayPauseCommand` подключён уже сейчас — тривиально добавить, иначе кнопка Play/Pause на пульте будет мертва во время смоук-теста.
- Никакого кастомного transport bar — используются встроенные элементы управления `AVPlayerViewController` (то же правило, что и в Phase 7).
- `customInfoViewController` не устанавливается в этой фазе — оставлен как есть по умолчанию; это осознанно, Phase 7 добавит `EPGInfoViewController`.
- Кнопка "Go to Playlists" в `ContentUnavailableView` должна быть фокусируема и иметь `accessibilityHint` вида "Opens the Playlists tab".
- Поскольку в этой фазе нет retry/backoff, битый URL потока покажет либо системный экран ошибки `AVPlayerViewController`, либо замёрзший чёрный экран — приемлемо для ручного смоук-теста, **не приемлемо для продакшена** (это разрыв, который закрывает Phase 7).

### Tests to write

`Tests/PresentationTests/PlayerViewModelTests.swift`:
```
@Test func init_setsChannelProperty()
@Test func init_createsPlayerWithChannelStreamURL()
```

Явных новых тестов на `ChannelListViewModel` не требуется: `onNavigateToPlaylists` — чистое View-уровневое замыкание без логики, которую имело бы смысл покрывать юнит-тестом на вьюмодели.

Ручная проверка (для этой фазы она важнее, чем обычно, — сама фаза именно про то, чтобы пройти флоу руками):
1. Чистая установка на симулятор → вкладка Channels показывает "No Playlists" с кнопкой "Go to Playlists".
2. Тап по кнопке → `TabView` переключается на вкладку Playlists.
3. Добавить плейлист с валидным M3U URL → дождаться парсинга → вернуться на вкладку Channels → каналы появляются **без перезапуска приложения** (проверяет исправление `.task(id:)`).
4. Выбрать карточку канала → открывается `fullScreenCover`, поток начинает воспроизводиться через системные элементы управления `AVPlayerViewController`.
5. Нажать Menu на пульте → cover закрывается, состояние вкладки Channels (позиция прокрутки, фильтр категории) не сброшено.

### Опционально — визуальный polish (не входит в Definition of Done)

Дизайн-спека и UI kit уже лежат в `illustrations/` (`Stanis_Love_TV_Design_Specification.pdf`, `Stanis_Love_TV_UI_Kit.svg`). По желанию владельца, в рамках этой же фазы или отдельным PR можно:
- Заменить системные иллюстрации `ContentUnavailableView` на кастомные ассеты из UI kit для пустых состояний Channels/Playlists.
- Свериться со спекой по отступам/типографике уже реализованных `ChannelCardView`/`CategorySidebarView` (Phase 6) и точечно поправить расхождения с `Spacing`/`Typography`.

Это explicitly не входит в Definition of Done ниже — чтобы не раздувать фазу перед Phase 7. Оставлено на усмотрение владельца.

### Open Questions

1. Нужно ли включать опциональный визуальный polish (см. выше) в Definition of Done этой фазы, или он остаётся полностью отдельной задачей? План по умолчанию считает его вне скоупа.
2. Прямое владение `AVPlayer` в `PlayerViewModel` — оставить как есть в Phase 7 (просто добавить retry-логику в тот же класс) или вынести в `PlayerRepository`/`DefaultPlayerRepository` сразу ради тестируемости? Не блокирует эту фазу, но стоит решить до начала детального планирования Phase 7.

### Definition of Done

- `RootView.swift` использует `.task(id: appState.activePlaylistID)`; проверено переключением активного плейлиста на вкладке Playlists — вкладка Channels перезагружается без перезапуска приложения.
- Кнопка пустого состояния на вкладке Channels программно переключает `TabView` на вкладку Playlists — тупикового CTA больше нет.
- Тап по карточке канала открывает полноэкранный `AVPlayerViewController` и начинает воспроизведение `channel.streamURL`.
- Кнопка Menu стабильно закрывает плеер и возвращает на предыдущий экран в неизменном состоянии.
- `PlayerViewModel`/`VideoPlayerView`/`PlayerView` скомпилированы и структурированы так, что Phase 7 сможет расширить их на месте — без переименований и переносов файлов.
- Ноль регрессий в существующих тестах Phase 5/6.

### Статус: выполнено (2026-07-29)

Весь сквозной путь (пустое состояние → добавление плейлиста → список каналов с группировкой → воспроизведение) пройден руками в tvOS Simulator. По ходу реализации всплыли четыре бага, не предусмотренные исходным текстом фазы — все найдены и исправлены:

1. **`@Table` без явного имени** (`PlaylistRecord`, `ChannelRecord`, `FavoriteRecord`, `EPGProgramRecord`) — SQLiteData по умолчанию выводит имя таблицы как lower-camel-case множественное число от имени типа (`PlaylistRecord` → `"playlistRecords"`), а миграции создают `"playlists"`, `"channels"` и т.д. Без явного `@Table("playlists")` каждая запись в БД падала с `SQLite error 1: no such table`, которая расплывчато маскировалась под сетевую ошибку (см. пункт 3). Исправлено во всех четырёх `@Table`-структурах.
2. **Отсутствие ATS-исключений** — в проекте не было ни одного ключа `NSAppTransportSecurity`, а плейлисты/логотипы/потоки произвольных IPTV-провайдеров сплошь и рядом на `http`. Добавлен `StanisLoveTV/App/Info.plist` с `NSAllowsArbitraryLoads = true`, подключён через `INFOPLIST_FILE` при сохранённом `GENERATE_INFOPLIST_FILE = YES` (слияние, не замена). Осознанный выбор для IPTV-приложения: домены плейлистов заранее не известны, точечные `NSExceptionDomains` не применимы.
3. **`AppError.init(_:)` слишком широко перехватывает ошибки** — любая нераспознанная ошибка (включая, как выяснилось, `SQLite error` из пункта 1) превращалась в `.networkUnavailable` ("No internet connection"), что сильно затрудняло диагностику. Не переписывали целиком (не в скоупе фазы), но это стоит учитывать в Phase 7/11 при добавлении error-состояний.
4. **`AddPlaylistView` обрезал только `.whitespaces`, не `.whitespacesAndNewlines`** — вставленная через `⌘V` ссылка с завершающим переносом строки проходила валидацию URL, но падала уже на сетевом вызове. Исправлено на обеих `TextField` (M3U URL, EPG URL) и в имени плейлиста.
5. **`M3UParser` не поддерживал `#EXTGRP:`** — часть провайдеров (например, hls.gd) не кладёт `group-title` в атрибуты `#EXTINF`, а указывает группу отдельной строкой `#EXTGRP:`. Парсер её игнорировал как обычный комментарий, из-за чего все каналы проваливались в одну безымянную категорию. Добавлен fallback: `group-title` атрибут (если есть) → иначе `#EXTGRP:` → иначе `""`. Покрыто тремя тестами в `M3UParserTests.swift`.

Сверх исходного скоупа фазы добавлен dev-инструмент — оверлей технической статистики воспроизведения (битрейт, разрешение, число stalls, состояние буфера) в правом верхнем углу плеера, под флагом `PlayerDebugFlags.showStatsOverlay` (`Core/Constants/DebugFlags.swift`), включается/выключается одной строкой без UI. Источник данных — `AVPlayerItemAccessLog` + KVO на `AVPlayerItem`.

**Известное открытое наблюдение (не блокер)**: в tvOS Simulator при воспроизведении реального сетевого HLS-потока звук идёт, а видео-кадр не рендерится, хотя `presentationSize` корректно определяется декодером (например, 1934×1080) — то есть видеодорожка декодируется, но не композитится на экран. Похоже на ограничение Simulator (`AVPlayerLayer`/Metal), а не баг приложения; требует подтверждения на физическом Apple TV.

---

## Phase 7 — Video Player

**Goal**: Full-screen `AVPlayerViewController`, HLS stream playback, error display with retry, EPG current programme in transport bar's custom info area, Next/Previous channel switching within the launching screen's play context.

**Complexity**: XL  
**Depends on**: Phase 6.5 (minimal player skeleton already exists — this phase extends it in place)  
**HIGH RISK**: `AVPlayer` lifecycle, HLS error handling, stream retry with backoff. `AVPlayerViewController` must be correctly wrapped in `UIViewControllerRepresentable` or the system controls break. Player must live in `PlayerViewModel`, never in a View struct.

**NOTE**: Channel switching (next/previous) is now in scope for this phase — see "User Flow & Navigation Spec → Flow 3" above for the play-context design (ordered `[Channel]` + index, captured at launch, wrap-around, hidden when the context has 1 channel). `transportBarCustomMenuItems` hosts the Next/Previous actions.

### Files to create / modify

Phase 6.5 already created a minimal `PlayerViewModel` / `VideoPlayerView` / `PlayerView` skeleton (plain playback, no retry, no EPG info, no channel switching). This phase **extends those same files in place** — do not rename or recreate them.

| Path | Action | Notes |
|------|--------|-------|
| `StanisLoveTV/Domain/Repositories/PlayerRepository.swift` | Create | protocol exposing player actions |
| `StanisLoveTV/Data/Player/DefaultPlayerRepository.swift` | Create | owns `AVPlayer`, implements protocol |
| `StanisLoveTV/Data/Player/StreamHealthChecker.swift` | Create | HEAD request, 3s timeout, retries |
| `StanisLoveTV/Presentation/Player/PlayerViewModel.swift` | **Modify** (created in Phase 6.5) | add `currentProgram`, `playbackState`, `retryCount`/`retryTask`, `@Dependency(\.networkService)`, `@Dependency(\.fetchEPGUseCase)`, `startPlayback()`/`retry()`/`handleBack()` |
| `StanisLoveTV/Presentation/Player/VideoPlayerView.swift` | **Modify** (created in Phase 6.5) | add `customInfoViewController`, reserve `transportBarCustomMenuItems` |
| `StanisLoveTV/Presentation/Player/PlayerView.swift` | **Modify** (created in Phase 6.5) | add `playbackState == .error` → `PlayerErrorView` branch |
| `StanisLoveTV/Presentation/Player/EPGInfoViewController.swift` | Create | `UIViewController` for `customInfoViewController` |
| `StanisLoveTV/Presentation/Player/PlayerErrorView.swift` | Create | Error overlay with retry button |

### PlayerViewModel

```swift
@MainActor @Observable final class PlayerViewModel {
    var channel: Channel
    var currentProgram: EPGProgram?
    var playbackState: PlaybackState = .loading
    var error: AppError?

    @ObservationIgnored private var player: AVPlayer?
    @ObservationIgnored private var retryCount = 0
    @ObservationIgnored private var retryTask: Task<Void, Never>?
    @ObservationIgnored @Dependency(\.networkService) private var network
    @ObservationIgnored @Dependency(\.fetchEPGUseCase) private var fetchEPG

    enum PlaybackState { case loading, playing, paused, error, retrying(attempt: Int) }

    func startPlayback() async { ... }
    func retry() async { ... }
    func togglePlayback() { player?.rate == 0 ? player?.play() : player?.pause() }
    func handleBack() { ... }
}
```

### Retry logic

- Stream health check: HEAD request with 3-second timeout to `channel.streamURL`.
- On `AVPlayerItem.Status == .failed` OR health check fails → retry after 2^attempt seconds (1s, 2s, 4s).
- Maximum 3 retries, then set `playbackState = .error` and surface `PlayerErrorView`.
- On `retry()` from user — reset `retryCount = 0`, restart sequence.

### AVPlayerViewController setup

```swift
func makeUIViewController(context: Context) -> AVPlayerViewController {
    let vc = AVPlayerViewController()
    vc.player = player
    vc.showsPlaybackControls = true
    vc.customInfoViewController = EPGInfoViewController(program: currentProgram)
    // transportBarCustomMenuItems: reserved for future channel-switching feature
    return vc
}
```

`EPGInfoViewController` — minimal `UIViewController` showing programme title and time remaining as a `UILabel` stack. Update it by calling `context.coordinator.updateProgram(currentProgram)`.

### PlayerRepository protocol

```swift
protocol PlayerRepository: AnyObject, Sendable {
    func load(url: URL)
    func play()
    func pause()
    var statusPublisher: AsyncStream<PlayerStatus> { get }
}
enum PlayerStatus { case loading, playing, paused, failed(Error) }
```

This protocol allows `PlayerViewModel` to be tested without a real `AVPlayer`.

### tvOS-specific concerns

- `.onPlayPauseCommand` → `viewModel.togglePlayback()`
- `.onExitCommand` → dismiss the full-screen cover
- Do NOT build a custom transport bar — use `AVPlayerViewController`'s built-in controls.
- `customInfoViewController` must be updated whenever `currentProgram` changes.
- Channel switching via transport bar: **deferred** — no implementation in Phase 7.

### Tests to write

`Tests/PresentationTests/PlayerViewModelTests.swift` (extends the file created in Phase 6.5 — add these `@Test`s alongside the existing `init_setsChannelProperty` / `init_createsPlayerWithChannelStreamURL`):
```
@Test func startPlayback_setsLoadingState()
@Test func playbackFailure_triggersRetry()
@Test func threeRetries_setsErrorState()
@Test func userRetry_resetsRetryCount()
@Test func togglePlayback_switchesState()
```

Use a mock `PlayerRepository` (protocol-based).

---

## Phase 8 — EPG Guide

**Goal**: Guide tab shows a 24-hour horizontal timeline per channel. EPG data fetched from the active playlist's `epgURL`, cached with 24h TTL, shown stale-first. Current programme highlighted.

**Complexity**: XL  
**Depends on**: Phases 4, 5  
**HIGH RISK**: EPG timeline UI is one of the most complex SwiftUI layouts on tvOS. A naive approach with too many views causes focus engine overload and jank. Use `LazyHStack` per channel row, virtualize aggressively.

### Files to create

| Path | Notes |
|------|-------|
| `StanisLoveTV/Domain/UseCases/FetchEPGUseCase.swift` | TTL check, fetch, parse, store |
| `StanisLoveTV/Presentation/EPG/EPGViewModel.swift` | `@MainActor @Observable` |
| `StanisLoveTV/Presentation/EPG/EPGView.swift` | Guide tab root view |
| `StanisLoveTV/Presentation/EPG/EPGTimelineView.swift` | Horizontal scroll timeline |
| `StanisLoveTV/Presentation/EPG/EPGChannelRowView.swift` | Single channel's programme strip |
| `StanisLoveTV/Presentation/EPG/EPGProgramCellView.swift` | Single programme tile |
| `StanisLoveTV/Presentation/EPG/EPGNowIndicatorView.swift` | Vertical "now" line |

### EPG URL resolution at runtime

`EPGViewModel` receives `AppState` via its initialiser (same pattern as `ChannelListViewModel`). When `FetchEPGUseCase` runs, it determines the EPG URL in this order:

1. Read `appState.activePlaylistID` — the resolved UUID is passed as a parameter into the use case.
2. Look up the active playlist from the DB to retrieve `playlist.epgURL`.
3. Use `playlist.epgURL` if non-nil.
4. If `playlist.epgURL` is nil → show the empty state: "No EPG guide configured. Add an EPG URL to this playlist in Settings."

There is no fallback to a different playlist's EPG URL. EPG is always scoped to the active playlist.

When `appState.activePlaylistID` changes (user switched playlist in Settings), `EPGViewModel` observes it via `@Observable` and re-calls `loadIfNeeded()` automatically — no `Notification.Name` needed.

### EPGViewModel

```swift
@MainActor @Observable final class EPGViewModel {
    var programs: [String: [EPGProgram]] = [:]  // keyed by channelID
    var channels: [Channel] = []
    var isLoading = false
    var lastUpdated: Date?
    var error: AppError?
    var epgURL: URL?   // resolved from active playlist

    @ObservationIgnored private let appState: AppState
    @ObservationIgnored @Dependency(\.fetchEPGUseCase) private var fetchEPG
    @ObservationIgnored @Dependency(\.fetchChannelsUseCase) private var fetchChannels

    init(appState: AppState) {
        self.appState = appState
    }

    func loadIfNeeded() async {
        // 1. Read appState.activePlaylistID; pass to FetchEPGUseCase
        // 2. Resolve epgURL from active playlist record in DB
        // 3. Guard epgURL != nil else show empty state
        // 4. Check UserDefaults "epgLastFetchedAt"
        // 5. If > 24h ago or nil: fetch fresh; otherwise load from DB
    }
}
```

### FetchEPGUseCase flow

```
1. Resolve active playlist → read epgURL
2. Guard epgURL != nil → throw AppError.epgFetchFailed (no URL configured)
3. Read UserDefaults["epgLastFetchedAt"] as Date?
4. If nil OR Date().timeIntervalSince(last) > 86_400:
   a. Fetch XMLTV via networkService.downloadToCache(epgURL)
   b. Parse via XMLTVParser.parse(_:)
   c. For each channelID, call epgRepository.replaceAll(channelID:programs:)
   d. Write Date() to UserDefaults["epgLastFetchedAt"]
5. Else: return programs from DB (stale-ok path)
```

### EPG Timeline Layout (tvOS-specific)

- Outer: `ScrollView([.horizontal, .vertical])` — user can scroll both axes.
- Per row: `LazyHStack` of `EPGProgramCellView`.
- Cell width = proportional to programme duration: `duration.inMinutes * pointsPerMinute` (e.g., 4 pt/min → 60min = 240 pt).
- Time header row at top scrolls horizontally with content (use `coordinateSpace` or offset trick).
- "Now" indicator: a vertical `Rectangle` pinned at the current time position.
- Focus: each cell is focusable. On select → navigate to player with that channel.
- Cell `accessibilityValue`: `"\(program.title), \(timeRemainingFormatted) remaining"`.
- Large grids (100+ channels × 24h) can create thousands of views — `LazyHStack` is essential; do not use `HStack`.

### Tests to write

`Tests/DomainTests/FetchEPGUseCaseTests.swift`:
```
@Test func fetchEPG_callsNetworkWhenStale()
@Test func fetchEPG_usesDBWhenFresh()
@Test func fetchEPG_updatesLastFetchedDate()
@Test func fetchEPG_networkFailure_returnsCachedData()
@Test func fetchEPG_noEPGURL_throwsError()
```

`Tests/PresentationTests/EPGViewModelTests.swift`:
```
@Test func loadIfNeeded_triggersFetchWhenStale()
@Test func loadIfNeeded_skipsFetchWhenFresh()
@Test func loadIfNeeded_showsEmptyStateWhenNoEPGURL()
@Test func programs_keyedByChannelID()
```

---

## Phase 9 — Favorites

**Goal**: Heart button on channel card toggles favorite status. Favorites filter on Channels tab. `FavoriteRecord` in DB.

**Complexity**: S  
**Depends on**: Phase 6

### Files to create / modify

| Path | Action |
|------|--------|
| `StanisLoveTV/Data/Repositories/DefaultFavoriteRepository.swift` | Already stubbed; implement now |
| `StanisLoveTV/Domain/UseCases/ToggleFavoriteUseCase.swift` | Already stubbed; implement now |
| `StanisLoveTV/Presentation/Channels/FavoriteButtonView.swift` | Create — heart SF Symbol button |
| `StanisLoveTV/Presentation/Channels/ChannelListView.swift` | Modify — add Favorites filter toggle |

### ToggleFavoriteUseCase

```swift
struct ToggleFavoriteUseCase {
    var execute: (UUID) async throws -> Bool  // returns new isFavorite value
}
// liveValue: calls favoriteRepository.toggle(channelID:)
```

`DefaultFavoriteRepository.toggle(channelID:)`:
- If row exists → DELETE → return `false`
- If row doesn't exist → INSERT → return `true`
- Both in a single write transaction via `db.writer.write`.

### FavoriteButtonView (tvOS-specific)

- SF Symbol: `heart.fill` (red) when favorite, `heart` (white/secondary) when not.
- Focusable independently from the channel card (appears on focus of card or always visible).
- `accessibilityLabel`: `"Favorite"` / `"Remove from favorites"`.
- `accessibilityAddTraits(.isButton)`.
- Animation: `.symbolEffect(.bounce)` on toggle (tvOS 27 supports symbol effects).

### Tests to write

`Tests/DataTests/FavoriteRepositoryTests.swift`:
```
@Test func toggle_unfavorited_addsRecord()
@Test func toggle_favorited_deletesRecord()
@Test func fetchAll_returnsOnlyFavoritedIDs()
```

`Tests/DomainTests/ToggleFavoriteUseCaseTests.swift`:
```
@Test func toggle_returnsTrueWhenAdded()
@Test func toggle_returnsFalseWhenRemoved()
```

---

## Phase 10 — Settings Screen

**Goal**: Settings tab lists all playlists with refresh and delete actions, allows the user to **select the active playlist**, shows and edits the EPG URL per playlist, provides cache-clearing, and an About section.

**Complexity**: S  
**Depends on**: Phases 5, 9

### Files to create

| Path | Notes |
|------|-------|
| `StanisLoveTV/Presentation/Settings/SettingsViewModel.swift` | `@MainActor @Observable`; manages `activePlaylistID` |
| `StanisLoveTV/Presentation/Settings/SettingsView.swift` | `List`-based settings screen |
| `StanisLoveTV/Presentation/Settings/PlaylistRowView.swift` | Row with name, URL, active indicator, EPG URL, refresh/delete actions |
| `StanisLoveTV/Presentation/Settings/EditPlaylistView.swift` | Sheet for editing a playlist's name and EPG URL |

### SettingsViewModel

```swift
@MainActor @Observable final class SettingsViewModel {
    var playlists: [Playlist] = []
    var isClearing = false
    var error: AppError?

    @ObservationIgnored private let appState: AppState   // source of truth for activePlaylistID
    @ObservationIgnored @Dependency(\.fetchPlaylistsUseCase) private var fetchPlaylists
    @ObservationIgnored @Dependency(\.refreshPlaylistUseCase) private var refreshPlaylist
    @ObservationIgnored @Dependency(\.deletePlaylistUseCase) private var deletePlaylist
    @ObservationIgnored @Dependency(\.fileCacheManager) private var cacheManager

    init(appState: AppState) {
        self.appState = appState
    }

    var activePlaylistID: UUID? { appState.activePlaylistID }

    func load() async { ... }
    func setActivePlaylist(id: UUID) {
        appState.activePlaylistID = id   // @Observable propagates to ChannelListViewModel + EPGViewModel
    }
    func refresh(playlistID: UUID) async { ... }
    func delete(playlistID: UUID) async { ... }
    func saveEPGURL(playlistID: UUID, url: URL?) async { ... }  // calls playlistRepository.updateEPGURL
    func clearCache() async { ... }
}
```

### SettingsView

Sections:
1. **Active Playlist** — picker or a list where each row has a checkmark when active. Tapping a playlist row sets it as active. Immediately updates `activePlaylistID` in UserDefaults.
2. **Playlists** — `ForEach` of `PlaylistRowView`. Each row shows:
   - Playlist name + source URL
   - EPG URL (editable — tap to open `EditPlaylistView` sheet)
   - "Refresh" button
   - "Delete" button (with confirmation dialog)
3. **Add Playlist** — button that navigates to `AddPlaylistView`.
4. **Cache** — "Clear EPG Cache" button, "Clear M3U Cache" button.
5. **About** — App version from `Bundle.main.infoDictionary`, build number.

> **Design decision**: "Active playlist" and "Playlists list" may be combined into a single section where the active row is marked with a checkmark SF Symbol (`checkmark.circle.fill`). This is more tvOS-idiomatic than a separate picker.

### EditPlaylistView

A modal sheet (`.sheet`) with:
- Read-only display of playlist name and M3U URL.
- Editable text field for EPG URL (labelled "EPG/XMLTV URL (optional)").
- "Save" and "Cancel" buttons.
- On save: calls `settingsViewModel.saveEPGURL(playlistID:url:)`.
- Validates the EPG URL format before saving; shows inline error if invalid.

### Active Playlist Change Propagation

**DECISION (finalised)**: Uses `@Observable AppState`, NOT `Notification.Name`. There is no `Notification.Name("activePlaylistDidChange")` anywhere in the codebase.

When `SettingsViewModel.setActivePlaylist(id:)` is called:
1. Write `appState.activePlaylistID = id`.
2. `AppState.didSet` persists the new value to `UserDefaults["activePlaylistID"]` automatically.
3. `@Observable` automatically invalidates any view or `withObservationTracking` block that read `appState.activePlaylistID` — `ChannelListViewModel` and `EPGViewModel` react without explicit notification wiring.

### tvOS-specific concerns

- tvOS has no swipe gesture — delete must be a button in the row or a context menu via `.contextMenu`.
- Use `.focusable()` on each row; focusable buttons inside the row must be individually addressable.
- Confirmation dialogs for destructive actions (delete playlist, clear cache) via `.confirmationDialog`.
- `.onExitCommand` should dismiss any presented confirmation.
- Active playlist indicator: use `checkmark.circle.fill` SF Symbol in the row.

### Tests to write

`Tests/PresentationTests/SettingsViewModelTests.swift`:
```
@Test func load_fetchesPlaylists()
@Test func setActivePlaylist_updatesAppStateActivePlaylistID()
@Test func setActivePlaylist_persistsToUserDefaults()       // via AppState.didSet
@Test func delete_removesFromList()
@Test func delete_clearsActiveIDIfMatchAndFallsBackToFirst()
@Test func saveEPGURL_updatesPlaylistRecord()
@Test func clearCache_callsCacheManager()
@Test func refresh_updatesLastUpdatedDate()
```

Test pattern — pass a fresh `AppState` instance per test:
```swift
@Test func setActivePlaylist_updatesAppStateActivePlaylistID() async {
    let appState = AppState()
    let viewModel = SettingsViewModel(appState: appState)
    let id = UUID()
    viewModel.setActivePlaylist(id: id)
    #expect(appState.activePlaylistID == id)
}
```

---

## Phase 11 — Polish & Hardening

**Goal**: All empty states, all loading states, all error states wired up. VoiceOver tested. No magic numbers. No force-unwraps. Build passes SwiftLint (if configured). App ships.

**Complexity**: L  
**Depends on**: All previous phases

### Tasks

#### Error States

- Every ViewModel with an `error: AppError?` property must have a corresponding `.alert` on its View.
- `AppError.errorDescription` and `AppError.recoverySuggestion` must be non-nil for all cases.
- Player error → `PlayerErrorView` with "Retry" + "Exit" buttons (both focusable).
- Playlist fetch error → inline error message in the playlist row with a "Retry" button.
- EPG fetch error → "Last updated: X" label with stale data still visible (never block the UI).

#### Empty States

- Channels tab with no playlists: illustration + "Add a playlist to get started" + CTA button.
- Channels tab with playlist but no channels: "No channels found. Try refreshing." with a Refresh button.
- EPG tab with no EPG URL configured on active playlist: "No EPG guide configured. Add an EPG URL to this playlist in Settings." with a Settings button.
- Favorites filter with no favorites: "No favorites yet. Press and hold a channel to add."
- Search with no results: "No channels match '\(query)'."

#### Loading States

- Full-screen `ProgressView` overlay with channel count progress for initial M3U fetch (if implementable).
- Shimmer skeleton cards in channel grid while loading (optional but recommended).
- Spinner in EPG rows while EPG is fetching.

#### VoiceOver & Accessibility Audit

- Test every screen with tvOS VoiceOver (Simulator → Settings → Accessibility → VoiceOver).
- All focusable elements have `accessibilityLabel`, `accessibilityHint`, and appropriate `accessibilityAddTraits`.
- Dynamic Type: all text uses semantic font sizes (`.title`, `.body`, `.caption`), never hardcoded `pt` in Text views.
- `Image(decorative:)` for logos and decorative art (Kingfisher images get `.accessibilityHidden(true)` modifier).
- EPG programme cells: `accessibilityValue` = `"\(program.title), ends at \(endTime.formatted(.dateTime.hour().minute()))"`.

#### tvOS Remote Completeness Audit

- Every screen: `.onExitCommand` present? ✓
- Player: `.onPlayPauseCommand` present? ✓
- Player channel switch: deferred — not audited in this phase.
- EPG timeline: D-pad navigation moves between cells? ✓

#### Constants Audit

- Zero `CGFloat` literals in View files — all through `Spacing.*` or `TVSize.*`.
- Zero hardcoded strings in UI — use string constants or `LocalizedStringKey` (localization not required but no raw strings).

#### Performance

- `LazyVGrid` / `LazyHStack` verified for channel grid and EPG timeline.
- `Task` cancelled in `deinit` of ViewModels where long-running tasks exist.
- Kingfisher disk cache limit configured (e.g., 200 MB for channel logos).
- Foreground refresh throttle verified: does not fire when `lastFetched` is recent.

#### Tests to write

`Tests/PresentationTests/ErrorHandlingTests.swift`:
```
@Test func channelListViewModel_errorState_isSetOnNetworkFailure()
@Test func epgViewModel_showsStaleDataOnFetchFailure()
@Test func playerViewModel_errorStateAfterMaxRetries()
```

---

## Cross-Cutting Concerns

### Dependency Graph Summary

All `DependencyValues` extensions consolidated in `Core/Dependencies/DependencyValues+.swift`:

| Key | Type | Provided by |
|-----|------|------------|
| `database` | `DatabaseStack` | `DatabaseStack.swift` |
| `networkService` | `NetworkService` | `NetworkService.swift` |
| `fileCacheManager` | `FileCacheManager` | `FileCacheManager.swift` |
| `channelRepository` | `any ChannelRepository` | `DefaultChannelRepository` |
| `playlistRepository` | `any PlaylistRepository` | `DefaultPlaylistRepository` |
| `epgRepository` | `any EPGRepository` | `DefaultEPGRepository` |
| `favoriteRepository` | `any FavoriteRepository` | `DefaultFavoriteRepository` |
| `fetchChannelsUseCase` | `FetchChannelsUseCase` | inline `liveValue` |
| `fetchPlaylistsUseCase` | `FetchPlaylistsUseCase` | inline `liveValue` |
| `addPlaylistUseCase` | `AddPlaylistUseCase` | inline `liveValue` |
| `deletePlaylistUseCase` | `DeletePlaylistUseCase` | inline `liveValue` |
| `refreshPlaylistUseCase` | `RefreshPlaylistUseCase` | inline `liveValue` |
| `fetchEPGUseCase` | `FetchEPGUseCase` | inline `liveValue` |
| `toggleFavoriteUseCase` | `ToggleFavoriteUseCase` | inline `liveValue` |
| `searchChannelsUseCase` | `SearchChannelsUseCase` | inline `liveValue` |

### Schema Versions

| Version | Name | Changes |
|---------|------|---------|
| v1 | `v1_initial` | Creates `playlists`, `channels`, `favorites`, `epgPrograms` + indexes |
| v2 | `v2_playlist_epg_url` | `ALTER TABLE playlists ADD COLUMN "epgURL" TEXT` |

### UserDefaults Keys

| Key | Type | Managed by | Purpose |
|-----|------|-----------|---------|
| `"activePlaylistID"` | `String` (UUID) | `AppState` exclusively | Which playlist is currently active; read in `AppState.init()`, written in `AppState.activePlaylistID.didSet` |
| `"epgLastFetchedAt"` | `Date` (ISO string) | `FetchEPGUseCase` | EPG 24h TTL tracking |
| `"lastWatchedChannelID"` | `String` (UUID) | TBD | Resume last channel (optional Phase 11 enhancement) |

**No repository, ViewModel, or use case may read or write `"activePlaylistID"` directly.** All access goes through `AppState`.

---

## Risk Register

| Risk | Severity | Phase | Mitigation |
|------|----------|-------|-----------|
| XMLTV timezone parsing produces wrong times | HIGH | 4 | Test with UTC, +0100, -0500 offsets. Use `en_US_POSIX` locale. |
| Migration DDL error requires new migration version | HIGH | 3 | Review DDL carefully. Use STRICT mode to catch type mismatches at dev time. Never edit v1_initial. |
| AVPlayer lifecycle / memory leak | HIGH | 7 | Owned by `PlayerViewModel` (not View). Cancel KVO observers in `deinit`. Protocol-based for testability. |
| EPG timeline focus engine overload (100+ channels) | MEDIUM | 8 | `LazyHStack` mandatory. Profile with tvOS Simulator performance gauge before ship. |
| M3U playlist with 10,000+ channels causes UI jank | MEDIUM | 5, 6 | Parse on background Task. Insert in batch write. Display with `LazyVGrid`. |
| `customInfoViewController` update timing | MEDIUM | 7 | Update in `updateUIViewController` coordinator. Guard against nil program. |
| Focus trap in custom EPG timeline | MEDIUM | 8 | Explicit `.focusSection()` + test with tvOS Simulator VoiceOver. |
| `activePlaylistID` points to deleted playlist | MEDIUM | 1, 10 | `DeletePlaylistUseCase` sets `appState.activePlaylistID = nil` if deleted ID matches; `ChannelListViewModel.load()` falls back to first available playlist and re-sets `appState.activePlaylistID`. All through `AppState` — no direct UserDefaults mutation in use cases. |
| M3U `url-tvg` points to invalid or huge XMLTV file | LOW | 4, 8 | `checkStreamHealth` before downloading. Stream to cache file, not memory. |
| Foreground refresh fires too frequently | LOW | 5 | 15-minute throttle via `AppConstants.playlistRefreshInterval` in `Core/Constants/AppConstants.swift`. Adjust the constant to change the interval without touching business logic. |
| Stream URL force-unwrap in domainModel | LOW | 3 | Validated at M3U parse time. Document assumption in code comment. |
| Minimal Phase 6.5 player has no retry/backoff | LOW | 6.5 | Acceptable only for manual smoke-testing in the simulator; a broken stream shows the system AVKit error UI or a frozen frame instead of `PlayerErrorView`. Phase 7 closes this gap — do not ship Phase 6.5's player standalone to TestFlight/production. |

---

## Resolved Decisions

All open questions have been answered and incorporated above. Zero open questions remain. Plan is ready to implement.

| # | Question | Decision |
|---|----------|----------|
| 1 | EPG URL source | Optional per-playlist field. User can enter manually in Settings. If blank, auto-extracted from M3U header `url-tvg` attribute. Manual entry takes priority over extracted value. |
| 2 | Multi-playlist deduplication | No deduplication. Duplicate channels from separate playlists appear as separate entries when each playlist is active. |
| 3 | Background playlist refresh | Auto-refresh on app foreground (`ScenePhase.active`). Throttled to max once per `AppConstants.playlistRefreshInterval` (15 minutes, defined in `Core/Constants/AppConstants.swift`). User can also refresh manually from Settings. |
| 4 | Player channel switching | Resolved in "User Flow & Navigation Spec → Flow 3" (added post-Phase 6). In scope for Phase 7: Next/Previous via `transportBarCustomMenuItems`, play context = ordered `[Channel]` + index captured at launch (grid/search/guide), wrap-around, hidden when context has 1 channel. |
| 5 | Channel browser scope | Only the currently active playlist. Active playlist is selected in Settings. Only one playlist active at a time. `AppState` reads/writes `activePlaylistID` from UserDefaults; injected at root via `.environment(appState)`. |
| 6 | Active playlist propagation mechanism | `@Observable AppState` injected via `@Environment`. `Notification.Name("activePlaylistDidChange")` is **not used** anywhere. `ChannelListViewModel` and `EPGViewModel` receive `AppState` via init and observe `appState.activePlaylistID` directly. `SettingsViewModel` writes `appState.activePlaylistID` to propagate changes. **Caveat found post-Phase 6** (see "User Flow & Navigation Spec → Correctness gap"): `@Observable` only auto-invalidates code that *reads* the property inside a view body — it does not re-run an already-completed `.task`. `RootView` must key the load task as `.task(id: appState.activePlaylistID)`, not a bare `.task`, or the reload never fires after the first launch. |
| 7 | Foreground refresh throttle interval | 15 minutes confirmed. Constant: `AppConstants.playlistRefreshInterval = 15 * 60` in `StanisLoveTV/Core/Constants/AppConstants.swift`. |
| 8 | Channels empty-state CTA (Open Question #1 из Phase 6) | Resolved in Phase 6.5 → Шаг 2. `ChannelListView` receives an `onNavigateToPlaylists: () -> Void` closure from `MainTabView`; the "No Playlists" `ContentUnavailableView` action button calls it, which sets `selectedTab = .playlists` on the `TabView(selection:)` binding. No deep link, no `NavigationPath` involved — pure tab-selection state local to `MainTabView`. |
