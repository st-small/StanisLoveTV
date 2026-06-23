import Foundation

enum AppError: LocalizedError {
    case networkUnavailable
    case playbackFailed(String)
    case playlistParseError(String)
    case epgFetchFailed
    case streamURLInvalid
    case databaseError(String)

    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "No internet connection"
        case .playbackFailed(let reason):
            return "Playback failed: \(reason)"
        case .playlistParseError(let detail):
            return "Playlist parse error: \(detail)"
        case .epgFetchFailed:
            return "Failed to fetch EPG data"
        case .streamURLInvalid:
            return "Stream URL is invalid"
        case .databaseError(let detail):
            return "Database error: \(detail)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "Check your network connection and try again."
        case .playbackFailed:
            return "Try a different stream or check your connection."
        case .playlistParseError:
            return "Verify the playlist URL is correct."
        case .epgFetchFailed:
            return "EPG data may be temporarily unavailable."
        case .streamURLInvalid:
            return "The stream URL in your playlist is malformed."
        case .databaseError:
            return "Restart the app. If the problem persists, reinstall."
        }
    }
}
