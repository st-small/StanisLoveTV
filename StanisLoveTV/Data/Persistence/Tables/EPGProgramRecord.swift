import Foundation
import SQLiteData

@Table nonisolated struct EPGProgramRecord: Identifiable {
    let id: UUID
    var channelID: String
    var title: String
    var startTime: Date
    var endTime: Date
    var programDescription: String?
    var fetchedAt: Date
}

extension EPGProgramRecord {
    nonisolated var domainModel: EPGProgram {
        EPGProgram(
            id: id,
            channelID: channelID,
            title: title,
            startTime: startTime,
            endTime: endTime,
            description: programDescription
        )
    }
}
