import SwiftUI

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
