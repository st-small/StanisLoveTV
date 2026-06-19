# Architecture Rules

Always-loaded rules for Clean Architecture, DI, state management, and navigation.

## Layers

```
Presentation  →  Domain  ←  Data
    (UI)       (Business)  (Network/Storage)
```

- **Domain** — pure Swift, no UIKit/SwiftUI/SQLiteData/AVFoundation imports
- **Data** — implements Domain protocols, owns DB and network
- **Presentation** — owns ViewModels, calls use cases, no business logic in Views

### Domain Layer
- Entities: pure `struct` — `Channel`, `Playlist`, `EPGProgram`, `Category`
- Repository protocols live here (`ChannelRepository`, `EPGRepository`, …)
- Use cases: one public `execute` closure, one responsibility
- No `import` of any framework except Foundation primitives

### Data Layer
- Implements repository protocols from Domain
- `@Table` structs live in `Data/Persistence/Tables/` — never exposed to Presentation
- Every `@Table` struct has a `domainModel` extension that maps to the Domain entity
- `AVPlayer` lives here, exposed to Presentation via a protocol

### Presentation Layer
- `@MainActor @Observable final class` for every ViewModel — never `ObservableObject`
- Views own ViewModels: `@State private var viewModel = SomeViewModel()`
- `@ObservationIgnored @Dependency` on every dependency inside `@Observable` — required, otherwise compiler error
- No `@EnvironmentObject` — pass via init or `@Environment`

## IPTV Domain Entities

```swift
struct Channel: Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    let streamURL: URL
    let logoURL: URL?
    let groupTitle: String
    let tvgID: String?      // links to EPGProgram.channelID
    var isFavorite: Bool
}

struct Playlist: Identifiable, Sendable {
    let id: UUID
    let name: String
    let url: URL
    let type: PlaylistType  // .m3u, .m3uPlus
    var epgURL: URL?        // manual override; if nil, extracted from M3U header url-tvg
    var lastUpdated: Date?
}

struct EPGProgram: Identifiable, Sendable {
    let id: UUID
    let channelID: String
    let title: String
    let startTime: Date
    let endTime: Date
    let description: String?
}
```

## Dependency Injection — swift-dependencies

```swift
struct FetchChannelsUseCase {
    var execute: (UUID) async throws -> [Channel]   // UUID = playlistID
}

extension FetchChannelsUseCase: DependencyKey {
    // static var (not let) — @Dependency resolves at call time, not at module load
    static var liveValue: Self {
        .init { playlistID in
            @Dependency(\.channelRepository) var repo
            return try await repo.fetchAll(playlistID: playlistID)
        }
    }
    static let testValue = FetchChannelsUseCase(
        execute: { unimplemented("FetchChannelsUseCase.execute") }
    )
}

extension DependencyValues {
    var fetchChannelsUseCase: FetchChannelsUseCase {
        get { self[FetchChannelsUseCase.self] }
        set { self[FetchChannelsUseCase.self] = newValue }
    }
}
```

All `DependencyValues` extensions live in `Core/Dependencies/DependencyValues+.swift`.

## ViewModel Pattern

```swift
@MainActor
@Observable
final class ChannelListViewModel {
    var channels: [Channel] = []
    var isLoading = false
    var error: AppError?

    @ObservationIgnored
    @Dependency(\.fetchChannelsUseCase) private var fetchChannels

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            channels = try await fetchChannels()
        } catch {
            self.error = AppError(error)
        }
    }
}
```

## Navigation

- Root shell: `TabView` with Channels / Guide / Playlists / Settings tabs
- Drill-down: `NavigationStack` + `NavigationPath` inside each tab
- Player: `.fullScreenCover(isPresented:)` over any tab

## Error Handling

```swift
enum AppError: LocalizedError {
    case networkUnavailable
    case playbackFailed(String)
    case playlistParseError(String)
    case epgFetchFailed
    case streamURLInvalid
    var errorDescription: String? { ... }
    var recoverySuggestion: String? { ... }
}
```

- Errors surfaced via `.alert`, never `print()`
- Playback errors → retry button in player overlay
- Playlist errors → inline error state in list

## M3U Parsing Rules

- Parse `#EXTM3U` header and `#EXTINF` directives
- Extract: `tvg-id`, `tvg-name`, `tvg-logo`, `group-title`
- Malformed lines → warning, not fatal error
- Parsing on background `Task`, never on `@MainActor`
- Return `Result<[Channel], ParseError>` at use case boundary
