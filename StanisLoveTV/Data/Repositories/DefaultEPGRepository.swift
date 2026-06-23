import Dependencies
import Foundation
import SQLiteData

final class DefaultEPGRepository: EPGRepository {
    @Dependency(\.database) private var db

    func fetchPrograms(channelID: String, after: Date) async throws -> [EPGProgram] {
        try await db.writer.read { database in
            try EPGProgramRecord
                .where { $0.channelID.eq(channelID) }
                .where { $0.endTime.gt(after) }
                .order { $0.startTime }
                .fetchAll(database)
                .map(\.domainModel)
        }
    }

    func replaceAll(channelID: String, programs: [EPGProgram]) async throws {
        let cutoff = Date(timeIntervalSinceNow: -172_800)
        try await db.writer.write { database in
            try EPGProgramRecord
                .where { $0.channelID.eq(channelID) }
                .delete()
                .execute(database)

            if !programs.isEmpty {
                let now = Date()
                let drafts = programs.map { program in
                    EPGProgramRecord.Draft(
                        id: program.id,
                        channelID: program.channelID,
                        title: program.title,
                        startTime: program.startTime,
                        endTime: program.endTime,
                        programDescription: program.description,
                        fetchedAt: now
                    )
                }
                try EPGProgramRecord.insert { drafts }.execute(database)
            }

            try EPGProgramRecord
                .where { $0.fetchedAt.lt(cutoff) }
                .delete()
                .execute(database)
        }
    }

    func pruneStale(olderThan: Date) async throws {
        try await db.writer.write { database in
            try EPGProgramRecord
                .where { $0.fetchedAt.lt(olderThan) }
                .delete()
                .execute(database)
        }
    }
}
