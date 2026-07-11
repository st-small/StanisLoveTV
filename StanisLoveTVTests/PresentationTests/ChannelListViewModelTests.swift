import Testing
import Foundation
import Dependencies
@testable import StanisLoveTV

@Suite("ChannelListViewModel")
@MainActor
struct ChannelListViewModelTests {

    private func makeViewModel(appState: AppState = AppState()) -> ChannelListViewModel {
        ChannelListViewModel(appState: appState)
    }

    @Test("load() populates channels and derives categories")
    func load_populatesChannelsAndCategories() async {
        let channels = [
            Channel.mock(name: "BBC One", groupTitle: "UK"),
            Channel.mock(name: "BBC Two", groupTitle: "UK"),
            Channel.mock(name: "CNN", groupTitle: "News")
        ]
        let appState = AppState()
        appState.activePlaylistID = UUID()

        await withDependencies {
            $0.fetchChannelsUseCase.execute = { _ in channels }
        } operation: {
            let viewModel = makeViewModel(appState: appState)
            await viewModel.load()
            #expect(viewModel.channels.count == 3)
            #expect(viewModel.categories.count == 2)
            #expect(viewModel.isLoading == false)
        }
    }

    @Test("load() passes activePlaylistID from AppState to use case")
    func load_usesActivePlaylistIDFromAppState() async {
        let knownID = UUID()
        let appState = AppState()
        appState.activePlaylistID = knownID

        var receivedID: UUID?

        await withDependencies {
            $0.fetchChannelsUseCase.execute = { id in
                receivedID = id
                return []
            }
        } operation: {
            let viewModel = makeViewModel(appState: appState)
            await viewModel.load()
            #expect(receivedID == knownID)
        }
    }

    @Test("load() falls back to first playlist when no active ID is set")
    func load_fallsBackToFirstPlaylistWhenNoActiveIDSet() async {
        let fallbackID = UUID()
        let appState = AppState()
        appState.activePlaylistID = nil

        await withDependencies {
            $0.fetchPlaylistsUseCase.execute = { [Playlist.mock(id: fallbackID)] }
            $0.fetchChannelsUseCase.execute = { _ in [Channel.mock()] }
        } operation: {
            let viewModel = makeViewModel(appState: appState)
            await viewModel.load()
            #expect(appState.activePlaylistID == fallbackID)
            #expect(viewModel.channels.count == 1)
        }
    }

    @Test("load() shows empty state when no playlists exist")
    func load_showsEmptyStateWhenNoPlaylists() async {
        let appState = AppState()
        appState.activePlaylistID = nil

        await withDependencies {
            $0.fetchPlaylistsUseCase.execute = { [] }
        } operation: {
            let viewModel = makeViewModel(appState: appState)
            await viewModel.load()
            #expect(viewModel.channels.isEmpty)
            #expect(viewModel.hasActivePlaylists == false)
            #expect(viewModel.isLoading == false)
        }
    }

    @Test("filteredChannels filters by selected category")
    func filteredChannels_filtersBySelectedCategory() async {
        let appState = AppState()
        appState.activePlaylistID = UUID()
        let channels = [
            Channel.mock(name: "Match 1", groupTitle: "Sports"),
            Channel.mock(name: "Film 1", groupTitle: "Movies"),
            Channel.mock(name: "Match 2", groupTitle: "Sports")
        ]

        await withDependencies {
            $0.fetchChannelsUseCase.execute = { _ in channels }
        } operation: {
            let viewModel = makeViewModel(appState: appState)
            await viewModel.load()
            viewModel.selectedCategory = Category(groupTitle: "Sports", channelCount: 2)
            #expect(viewModel.filteredChannels.count == 2)
            #expect(viewModel.filteredChannels.allSatisfy { $0.groupTitle == "Sports" })
        }
    }

    @Test("filteredChannels returns all channels when no category is selected")
    func filteredChannels_returnsAllWhenNoCategorySelected() async {
        let appState = AppState()
        appState.activePlaylistID = UUID()
        let channels = [Channel.mock(), Channel.mock(), Channel.mock()]

        await withDependencies {
            $0.fetchChannelsUseCase.execute = { _ in channels }
        } operation: {
            let viewModel = makeViewModel(appState: appState)
            await viewModel.load()
            viewModel.selectedCategory = nil
            #expect(viewModel.filteredChannels.count == 3)
        }
    }

    @Test("search() returns matching channels from use case")
    func search_returnsMatchingChannels() async {
        let match = Channel.mock(name: "BBC One")
        let appState = AppState()
        appState.activePlaylistID = UUID()

        await withDependencies {
            $0.searchChannelsUseCase.execute = { _, _ in [match] }
        } operation: {
            let viewModel = makeViewModel(appState: appState)
            viewModel.searchQuery = "BBC"
            await viewModel.search()
            // Wait for debounce
            try? await Task.sleep(nanoseconds: 400_000_000)
            #expect(viewModel.searchResults.count == 1)
        }
    }

    @Test("search() clears results when query is whitespace-only")
    func search_emptyQuery_clearsResults() async {
        let appState = AppState()
        appState.activePlaylistID = UUID()

        await withDependencies {
            $0.searchChannelsUseCase.execute = { _, _ in [] }
        } operation: {
            let viewModel = makeViewModel(appState: appState)
            viewModel.searchResults = [Channel.mock(), Channel.mock()]
            viewModel.searchQuery = " "
            await viewModel.search()
            #expect(viewModel.searchResults.isEmpty)
        }
    }

    @Test("search() does not call use case when query is shorter than 2 characters")
    func search_shortQuery_doesNotCallUseCase() async {
        let appState = AppState()
        appState.activePlaylistID = UUID()

        await withDependencies {
            $0.searchChannelsUseCase.execute = { _, _ in
                Issue.record("SearchChannelsUseCase.execute should not be called for short query")
                return []
            }
        } operation: {
            let viewModel = makeViewModel(appState: appState)
            viewModel.searchQuery = "B"
            await viewModel.search()
            #expect(viewModel.searchResults.isEmpty)
        }
    }

    @Test("load() sets error when fetch fails")
    func error_isSetWhenFetchFails() async {
        let appState = AppState()
        appState.activePlaylistID = UUID()

        await withDependencies {
            $0.fetchChannelsUseCase.execute = { _ in throw AppError.networkUnavailable }
        } operation: {
            let viewModel = makeViewModel(appState: appState)
            await viewModel.load()
            #expect(viewModel.error != nil)
            #expect(viewModel.channels.isEmpty)
        }
    }

    @Test("categories are sorted alphabetically")
    func categories_areSortedAlphabetically() async {
        let appState = AppState()
        appState.activePlaylistID = UUID()
        let channels = [
            Channel.mock(groupTitle: "Sports"),
            Channel.mock(groupTitle: "Movies"),
            Channel.mock(groupTitle: "Kids"),
        ]

        await withDependencies {
            $0.fetchChannelsUseCase.execute = { _ in channels }
        } operation: {
            let viewModel = makeViewModel(appState: appState)
            await viewModel.load()
            let titles = viewModel.categories.map(\.groupTitle)
            #expect(titles == ["Kids", "Movies", "Sports"])
        }
    }
}
