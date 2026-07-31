import Testing
import Foundation
import Dependencies
@testable import StanisLoveTV

@Suite("PlaylistsViewModel")
@MainActor
struct PlaylistsViewModelTests {

    private func makeViewModel(appState: AppState = AppState()) -> PlaylistsViewModel {
        PlaylistsViewModel(appState: appState)
    }

    // MARK: - Tests

    @Test("load() populates playlists from use case")
    func load_populatesPlaylists() async {
        let mockPlaylists = [Playlist.mock(), Playlist.mock()]
        await withDependencies {
            $0.fetchPlaylistsUseCase.execute = { mockPlaylists }
        } operation: {
            let viewModel = makeViewModel()
            await viewModel.load()
            #expect(viewModel.playlists.count == 2)
        }
    }

    @Test("add() appends playlist to list")
    func add_appendsToList() async throws {
        let fetched = [Playlist.mock()]
        let url = URL(string: "http://example.com/test.m3u")!

        try await withDependencies {
            $0.addPlaylistUseCase.execute = { _ in }
            $0.fetchPlaylistsUseCase.execute = { fetched }
        } operation: {
            let viewModel = makeViewModel()
            try await viewModel.add(url: url, name: "Test", epgURL: nil)
            #expect(viewModel.playlists.count == 1)
        }
    }

    @Test("add() sets activePlaylistID when none is set")
    func add_setsActivePlaylistIDWhenNone() async throws {
        let fetched = [Playlist.mock()]
        let url = URL(string: "http://example.com/test.m3u")!
        var capturedID: UUID?

        try await withDependencies {
            $0.addPlaylistUseCase.execute = { _ in }
            $0.fetchPlaylistsUseCase.execute = { fetched }
        } operation: {
            let appState = AppState()
            let viewModel = PlaylistsViewModel(appState: appState)
            try await viewModel.add(url: url, name: "Test", epgURL: nil)
            capturedID = appState.activePlaylistID
        }

        #expect(capturedID != nil)
    }

    @Test("delete() removes playlist from list")
    func delete_removesFromList() async {
        let playlist = Playlist.mock()
        await withDependencies {
            $0.fetchPlaylistsUseCase.execute = { [playlist] }
            $0.deletePlaylistUseCase.execute = { _ in }
        } operation: {
            let viewModel = makeViewModel()
            await viewModel.load()
            await viewModel.delete(id: playlist.id)
            #expect(viewModel.playlists.isEmpty)
        }
    }

    @Test("delete() clears activePlaylistID when deleted playlist was active")
    func delete_clearsActivePlaylistIDIfMatch() async {
        let playlist = Playlist.mock()
        let appState = AppState()
        appState.activePlaylistID = playlist.id

        await withDependencies {
            $0.fetchPlaylistsUseCase.execute = { [playlist] }
            $0.deletePlaylistUseCase.execute = { _ in }
        } operation: {
            let viewModel = PlaylistsViewModel(appState: appState)
            await viewModel.load()
            await viewModel.delete(id: playlist.id)
            #expect(appState.activePlaylistID == nil)
        }
    }

    @Test("error is set on network failure during load")
    func error_isSetOnFailure() async {
        await withDependencies {
            $0.fetchPlaylistsUseCase.execute = { throw URLError(.notConnectedToInternet) }
        } operation: {
            let viewModel = makeViewModel()
            await viewModel.load()
            #expect(viewModel.error != nil)
        }
    }

    @Test("refreshActivePlaylistIfNeeded skips when fetched recently")
    func foregroundRefresh_skippedIfFetchedRecently() async {
        var refreshCalled = false
        let recentDate = Date().addingTimeInterval(-60)
        let playlist = Playlist.mock(lastUpdated: recentDate)

        await withDependencies {
            $0.fetchPlaylistsUseCase.execute = { [playlist] }
            $0.refreshPlaylistUseCase.execute = { _ in refreshCalled = true }
        } operation: {
            let appState = AppState()
            appState.activePlaylistID = playlist.id
            let viewModel = PlaylistsViewModel(appState: appState)
            await viewModel.load()
            await viewModel.refreshActivePlaylistIfNeeded()
            #expect(refreshCalled == false)
        }
    }

    @Test("refreshActivePlaylistIfNeeded triggers when playlist is stale")
    func foregroundRefresh_triggeredWhenStale() async {
        var refreshCalled = false
        let staleDate = Date().addingTimeInterval(-3600)
        let playlist = Playlist.mock(lastUpdated: staleDate)

        await withDependencies {
            $0.fetchPlaylistsUseCase.execute = { [playlist] }
            $0.refreshPlaylistUseCase.execute = { _ in refreshCalled = true }
        } operation: {
            let appState = AppState()
            appState.activePlaylistID = playlist.id
            let viewModel = PlaylistsViewModel(appState: appState)
            await viewModel.load()
            await viewModel.refreshActivePlaylistIfNeeded()
            #expect(refreshCalled == true)
        }
    }

    @Test("rehydrateCacheIfNeeded toggles isRehydratingCache during run")
    func rehydrateCacheIfNeeded_togglesIsRehydratingCacheDuringRun() async {
        let appState = AppState()
        var observedDuringRun = false

        await withDependencies {
            $0.rehydrateCacheUseCase.execute = {
                observedDuringRun = appState.isRehydratingCache
            }
        } operation: {
            let viewModel = PlaylistsViewModel(appState: appState)
            #expect(appState.isRehydratingCache == false)
            await viewModel.rehydrateCacheIfNeeded()
        }

        #expect(observedDuringRun == true)
        #expect(appState.isRehydratingCache == false)
    }

    @Test("rehydrateCacheIfNeeded is a no-op when the use case has nothing to do")
    func rehydrateCacheIfNeeded_noOpWhenAllPlaylistsAlreadyHaveChannels() async {
        var executeCallCount = 0
        let appState = AppState()

        await withDependencies {
            $0.rehydrateCacheUseCase.execute = { executeCallCount += 1 }
        } operation: {
            let viewModel = PlaylistsViewModel(appState: appState)
            await viewModel.rehydrateCacheIfNeeded()
            #expect(viewModel.error == nil)
        }

        #expect(executeCallCount == 1)
    }
}
