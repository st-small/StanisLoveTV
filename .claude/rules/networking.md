---
paths:
  - "StanisLoveTV/Data/Network/**"
  - "StanisLoveTV/Data/Parsers/**"
---

# Networking Rules

- `URLSession` async/await — no Alamofire unless auth interceptors are explicitly needed
- M3U playlists: background `URLSessionDownloadTask`, not in-memory `Data`
- Stream health check: HEAD request, 3s timeout, before handing URL to `AVPlayer`

```swift
struct NetworkService {
    var fetchData: (URL) async throws -> Data
    var downloadToCache: (URL, filename: String) async throws -> URL  // returns local file URL
    var checkStreamHealth: (URL) async throws -> Bool
}
```

Register as `@Dependency` in `Core/Dependencies/DependencyValues+.swift`.

## EPG Refresh Strategy

- Triggered by `EPGViewModel` on first open of the Guide tab
- TTL: 24h, tracked in `UserDefaults` key `"epgLastFetchedAt"` as `Date`
- On tab open: if `Date().timeIntervalSince(lastFetched) > 86_400` → fetch + parse + replace DB rows
- Offline: show stale data with "Last updated: …" label — no blocking error
- Pruning: in the same write transaction that inserts new rows, delete rows where `fetchedAt < now - 172_800` (48h)

## M3U Parsing

- Parse on background `Task` — never on `@MainActor`
- `#EXTM3U` header required; missing header → `ParseError.invalidFormat`
- `#EXTINF` attributes: `tvg-id`, `tvg-name`, `tvg-logo`, `group-title`
- Malformed `#EXTINF` line → log warning, skip row, continue parsing
- Parser `throws` and returns `M3UParseResult` — a struct with `channels: [Channel]` and `epgURL: URL?`
- EPG URL extraction: check `url-tvg` first, then `x-tvg-url`; return `nil` if neither present

```swift
struct M3UParseResult {
    let channels: [Channel]
    let epgURL: URL?        // extracted from M3U header, nil if absent
}
```
