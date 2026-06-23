import Foundation

protocol EPGRepository: Sendable {
    func fetchPrograms(channelID: String, after: Date) async throws -> [EPGProgram]
    func replaceAll(channelID: String, programs: [EPGProgram]) async throws
    func pruneStale(olderThan: Date) async throws
}
