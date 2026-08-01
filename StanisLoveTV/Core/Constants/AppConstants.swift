import Foundation

nonisolated enum AppConstants {
    /// Minimum interval between automatic foreground playlist refreshes.
    /// Set to 15 minutes to avoid hammering the server on every focus switch.
    static let playlistRefreshInterval: TimeInterval = 15 * 60

    /// Splash screen stays visible for at least this long, even if the
    /// playlist-existence check resolves faster.
    static let splashMinimumDuration: Duration = .seconds(2)
}
