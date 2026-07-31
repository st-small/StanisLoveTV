import Dependencies
import Foundation
import Observation

@MainActor
@Observable
final class ChannelListViewModel {
    var channels: [Channel] = []
    var categories: [Category] = []
    var selectedCategory: Category?
    var searchQuery: String = ""
    var searchResults: [Channel] = []
    var isLoading = false
    var error: AppError?
    var selectedChannel: Channel?

    @ObservationIgnored private let appState: AppState
    @ObservationIgnored @Dependency(\.fetchChannelsUseCase) private var fetchChannels
    @ObservationIgnored @Dependency(\.searchChannelsUseCase) private var searchChannels
    @ObservationIgnored @Dependency(\.fetchPlaylistsUseCase) private var fetchPlaylists

    @ObservationIgnored private var searchTask: Task<Void, Never>?

    init(appState: AppState) {
        self.appState = appState
    }

    var hasActivePlaylists: Bool { appState.activePlaylistID != nil }
    var isRestoringCache: Bool { appState.isRehydratingCache }

    var filteredChannels: [Channel] {
        guard let cat = selectedCategory else { return channels }
        return channels.filter { $0.groupTitle == cat.groupTitle }
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            var playlistID = appState.activePlaylistID

            if playlistID == nil {
                let playlists = try await fetchPlaylists.execute()
                if let first = playlists.first {
                    appState.activePlaylistID = first.id
                    playlistID = first.id
                } else {
                    channels = []
                    categories = []
                    return
                }
            }

            guard let resolvedID = playlistID else { return }
            channels = try await fetchChannels.execute(resolvedID)
            categories = deriveCategories(from: channels)
        } catch {
            self.error = AppError(error)
        }
    }

    func search() async {
        searchTask?.cancel()

        let trimmed = searchQuery.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 2, let playlistID = appState.activePlaylistID else {
            searchResults = []
            return
        }

        searchTask = Task {
            do {
                try await Task.sleep(nanoseconds: 300_000_000)
                guard !Task.isCancelled else { return }
                searchResults = try await searchChannels.execute(trimmed, playlistID)
            } catch is CancellationError {
                // expected — no-op
            } catch {
                self.error = AppError(error)
            }
        }
    }

    private func deriveCategories(from channels: [Channel]) -> [Category] {
        var counts: [String: Int] = [:]
        for channel in channels {
            counts[channel.groupTitle, default: 0] += 1
        }
        return counts
            .map { Category(groupTitle: $0.key, channelCount: $0.value) }
            .sorted { $0.groupTitle.localizedStandardCompare($1.groupTitle) == .orderedAscending }
    }
}
