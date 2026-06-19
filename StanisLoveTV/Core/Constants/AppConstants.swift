import Foundation

enum AppConstants {
    /// Minimum interval between automatic foreground playlist refreshes.
    /// Set to 15 minutes to avoid hammering the server on every focus switch.
    static let playlistRefreshInterval: TimeInterval = 15 * 60
}
