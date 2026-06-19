---
paths:
  - "StanisLoveTVTests/**"
  - "**/*Tests.swift"
  - "**/*Test.swift"
---

# Testing Rules

Framework: **Swift Testing** (`import Testing`) — not XCTest.
Assertions: `#expect(...)`, `#require(...)` — not `XCTAssert`.

## Coverage targets

| Layer | Target |
|-------|--------|
| Use Cases | 90%+ |
| ViewModels | 80%+ |
| Parsers (M3U, XMLTV) | 90%+ |
| Repositories | integration tests |

## Unit test pattern — withDependencies

```swift
@Test func loadChannelsPopulatesViewModel() async throws {
    let mockChannel = Channel.mock()
    await withDependencies {
        $0.fetchChannelsUseCase.execute = { [mockChannel] }
    } operation: {
        let vm = ChannelListViewModel()
        await vm.load()
        #expect(vm.channels.count == 1)
        #expect(vm.channels[0].name == mockChannel.name)
    }
}
```

## Integration test pattern — in-memory DatabaseQueue

Create `DatabaseStack` **outside** the `withDependencies` closure — `DatabaseQueue()` throws and the setup closure is non-throwing.

```swift
@Test func savesAndFetchesChannels() async throws {
    let inMemoryDB = DatabaseStack(writer: try DatabaseQueue())
    try await withDependencies {
        $0.database = inMemoryDB
    } operation: {
        let repo = DefaultChannelRepository()
        let playlistID = UUID()
        let channel = Channel.mock(playlistID: playlistID)
        try await repo.save([channel], playlistID: playlistID)
        let fetched = try await repo.fetchAll(playlistID: playlistID)
        #expect(fetched.count == 1)
        #expect(fetched[0].name == channel.name)
    }
}
```

## Parser unit test pattern

```swift
@Test func parseValidM3U() throws {
    let m3u = """
    #EXTM3U
    #EXTINF:-1 tvg-id="bbc1" tvg-name="BBC One" group-title="UK",BBC One
    http://example.com/bbc1.m3u8
    """
    let channels = try M3UParser().parse(m3u)
    #expect(channels.count == 1)
    #expect(channels[0].name == "BBC One")
    #expect(channels[0].groupTitle == "UK")
}
```

## Rules

- No `Thread.sleep` or `DispatchQueue.asyncAfter` — use `await` and `confirmation`
- `testValue` for every `DependencyKey` uses `unimplemented(...)` — forces explicit stubbing
- AVPlayer mocked via a protocol, not the concrete class
- No shared mutable state between tests — each test gets fresh dependencies
