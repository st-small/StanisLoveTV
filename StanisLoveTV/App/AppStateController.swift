import Dependencies
import Foundation
import Observation

@MainActor
@Observable
final class AppStateController {
    private(set) var phase: AppPhase = .splash
    private(set) var playlistGateState: PlaylistGateState = .locked

    @ObservationIgnored @Dependency(\.fetchPlaylistsUseCase) private var fetchPlaylists
    @ObservationIgnored private let splashMinimumDuration: Duration

    init(splashMinimumDuration: Duration = AppConstants.splashMinimumDuration) {
        self.splashMinimumDuration = splashMinimumDuration
    }

    /// Idempotent — safe to call more than once (e.g. if `RootView`'s `.task` re-runs).
    func start() async {
        guard phase == .splash else { return }
        async let delay: Void = sleepMinimumSplashDuration()
        let hasPlaylists = await fetchHasPlaylists()
        await delay
        playlistGateState = hasPlaylists ? .unlocked : .locked
        phase = .ready
    }

    /// Called by the gate overlay after a playlist has been saved successfully.
    func unlockGate() {
        playlistGateState = .unlocked
    }

    private func fetchHasPlaylists() async -> Bool {
        (try? await fetchPlaylists.execute())?.isEmpty == false
    }

    private func sleepMinimumSplashDuration() async {
        try? await Task.sleep(for: splashMinimumDuration)
    }
}
