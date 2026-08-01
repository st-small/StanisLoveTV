import SwiftUI

@main
struct StanisLoveTVApp: App {
    private let appState = AppState()
    private let appStateController = AppStateController()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(appStateController)
        }
    }
}
