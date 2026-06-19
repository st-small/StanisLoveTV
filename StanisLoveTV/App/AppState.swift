import Observation
import Foundation

@Observable
final class AppState {
    var activePlaylistID: UUID? {
        didSet {
            UserDefaults.standard.set(
                activePlaylistID?.uuidString,
                forKey: "activePlaylistID"
            )
        }
    }

    init() {
        if let raw = UserDefaults.standard.string(forKey: "activePlaylistID") {
            activePlaylistID = UUID(uuidString: raw)
        }
    }
}
