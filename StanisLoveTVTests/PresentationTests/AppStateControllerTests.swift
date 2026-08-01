import Testing
import Foundation
import Dependencies
@testable import StanisLoveTV

@Suite("AppStateController")
@MainActor
struct AppStateControllerTests {

    private func makeController(splashMinimumDuration: Duration = .zero) -> AppStateController {
        AppStateController(splashMinimumDuration: splashMinimumDuration)
    }

    // MARK: - Tests

    @Test("start() unlocks the gate when playlists exist")
    func start_unlocksGateWhenPlaylistsExist() async {
        await withDependencies {
            $0.fetchPlaylistsUseCase.execute = { [Playlist.mock()] }
        } operation: {
            let controller = makeController()
            await controller.start()
            #expect(controller.phase == .ready)
            #expect(controller.playlistGateState == .unlocked)
        }
    }

    @Test("start() locks the gate when there are no playlists")
    func start_locksGateWhenNoPlaylists() async {
        await withDependencies {
            $0.fetchPlaylistsUseCase.execute = { [] }
        } operation: {
            let controller = makeController()
            await controller.start()
            #expect(controller.phase == .ready)
            #expect(controller.playlistGateState == .locked)
        }
    }

    @Test("start() defaults to a locked gate when the fetch throws")
    func start_locksGateWhenFetchThrows() async {
        await withDependencies {
            $0.fetchPlaylistsUseCase.execute = { throw URLError(.unknown) }
        } operation: {
            let controller = makeController()
            await controller.start()
            #expect(controller.phase == .ready)
            #expect(controller.playlistGateState == .locked)
        }
    }

    @Test("start() does not finish before the configured minimum splash duration")
    func start_respectsMinimumSplashDuration() async throws {
        await withDependencies {
            $0.fetchPlaylistsUseCase.execute = { [] }
        } operation: {
            let controller = makeController(splashMinimumDuration: .milliseconds(200))
            let task = Task { await controller.start() }

            try? await Task.sleep(for: .milliseconds(50))
            #expect(controller.phase == .splash)

            await task.value
            #expect(controller.phase == .ready)
        }
    }

    @Test("start() is idempotent")
    func start_isIdempotent() async {
        var executeCallCount = 0
        await withDependencies {
            $0.fetchPlaylistsUseCase.execute = {
                executeCallCount += 1
                return []
            }
        } operation: {
            let controller = makeController()
            await controller.start()
            await controller.start()
            #expect(executeCallCount == 1)
            #expect(controller.phase == .ready)
        }
    }

    @Test("unlockGate() unlocks the gate without touching phase")
    func unlockGate_unlocksWithoutTouchingPhase() {
        let controller = makeController()
        controller.unlockGate()
        #expect(controller.playlistGateState == .unlocked)
        #expect(controller.phase == .splash)
    }
}
