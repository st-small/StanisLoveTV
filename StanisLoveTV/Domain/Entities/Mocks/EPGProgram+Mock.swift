import Foundation

extension EPGProgram {
    static func mock(
        id: UUID = UUID(),
        channelID: String = "mock-channel-id",
        title: String = "Mock Program",
        startTime: Date = Date(),
        endTime: Date = Date(timeIntervalSinceNow: 3600),
        description: String? = "Mock program description"
    ) -> EPGProgram {
        EPGProgram(
            id: id,
            channelID: channelID,
            title: title,
            startTime: startTime,
            endTime: endTime,
            description: description
        )
    }
}
