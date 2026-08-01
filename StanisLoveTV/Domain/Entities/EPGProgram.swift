import Foundation

nonisolated struct EPGProgram: Identifiable, Sendable {
    let id: UUID
    let channelID: String
    let title: String
    let startTime: Date
    let endTime: Date
    let description: String?
}
