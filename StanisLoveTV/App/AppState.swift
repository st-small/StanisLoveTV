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

    /// Transient — not persisted. If the process is killed mid-rehydration,
    /// the next cold start just starts over.
    var isRehydratingCache: Bool = false

    init() {
        if let raw = UserDefaults.standard.string(forKey: "activePlaylistID") {
            activePlaylistID = UUID(uuidString: raw)
        }
    }
}
