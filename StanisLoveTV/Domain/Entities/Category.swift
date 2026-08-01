import Foundation

nonisolated struct Category: Identifiable, Hashable, Sendable {
    var id: String { groupTitle }
    let groupTitle: String
    let channelCount: Int
}
